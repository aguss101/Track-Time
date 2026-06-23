# Track-Time — Documentación del Proyecto

> Documento de especificación para desarrollo en Claude Code.
> Repositorio: **Track-Time** (GitHub).

---

## 1. Objetivo

App **móvil personal** para medir tiempos de estudio/trabajo mediante un cronómetro vinculado a actividades predefinidas. Usuario único, sin login ni registro. Prioridad: **desarrollo rápido y funcionalidad núcleo sobre complejidad**.

---

## 2. Stack Técnico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Dart) |
| Shell nativa | Android (Java) + `MethodChannel` para comunicación Flutter ↔ Android |
| Build | Gradle (Groovy DSL) |
| Base de datos | Supabase (acceso vía **API REST + RPC**, no SDK) |
| Auth | `anon key` + políticas RLS en Supabase |
| IDE | VS Code |
| Deploy | No aplica — Flutter habla directo con Supabase, sin servidor que mantener |

### Arquitectura de comunicación

```
Flutter (Dart) → HTTP → Supabase REST API
```

Flutter llama directamente a Supabase REST. No hay backend intermedio.
La `anon key` vive en Flutter (app personal en el propio dispositivo, riesgo aceptado).
La lógica de métricas (sumas, promedios) se calcula en Dart a partir de los datos que retornan las funciones RPC de Supabase.

### Decisiones descartadas (no implementar)

- ❌ **UUID** → se usa `SERIAL` (IDs secuenciales).
- ❌ **Backend Java / Spring Boot** → eliminado. Flutter habla directo con Supabase.
- ❌ **Edge Functions** → las métricas se resuelven con funciones PostgreSQL (RPC).
- ❌ **Supabase Auth / login / registro** → usuario único.
- ❌ **Tabla `actividad_dias`** → reemplazada por columna array `dias`.
- ❌ **Claude Design** → no aplica (app móvil Flutter, no web).
- ❌ **service_role key** → se usa `anon key` + RLS.

---

## 3. Convenciones

- **Idioma**: schema, carpetas, archivos y funciones en **español**.
- **Nombres de archivo sin sufijo redundante**: un archivo dentro de `pantallas/` se llama `inicio.dart`, no `pantalla_inicio.dart`. Aplica a toda la estructura.
- **Timezone**: Argentina (UTC−3) fijo — `America/Argentina/Buenos_Aires`.
- **Semana**: Lunes a Domingo (ISO: lunes = 1, domingo = 7).

---

## 4. Base de Datos (Supabase)

### 4.1 Schema

```sql
CREATE TABLE grupos (
  id     SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  color  TEXT
);

CREATE TABLE actividades (
  id               SERIAL PRIMARY KEY,
  id_grupo         INT REFERENCES grupos(id) ON DELETE SET NULL,
  nombre           TEXT NOT NULL,
  color            TEXT NOT NULL,
  dias             SMALLINT[],   -- [1..7] 1=lunes ... 7=domingo
  meses            SMALLINT[],   -- [1..12]
  objetivo_diario  INT,
  objetivo_mensual INT,
  objetivo_semanal INT,
  objetivo_anual   INT,
  creado           TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE sesiones (
  id           SERIAL PRIMARY KEY,
  id_actividad INT REFERENCES actividades(id) ON DELETE CASCADE,
  iniciada     TIMESTAMPTZ NOT NULL,
  finalizada   TIMESTAMPTZ,
  duracion     INT           -- segundos, calculado por trigger al pausar
);
```

**Notas:**
- `ON DELETE SET NULL` en `actividades.id_grupo`: al borrar un grupo, las actividades quedan sin grupo (no se eliminan).
- `ON DELETE CASCADE` en `sesiones.id_actividad`: al borrar una actividad, sus sesiones se eliminan.
- `dias` y `meses` son arrays opcionales; sirven como guía organizativa, no obligan a realizar la actividad ese día.

### 4.2 Triggers

**1. Cálculo automático de `duracion` al pausar:**

```sql
CREATE OR REPLACE FUNCTION calcular_duracion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.finalizada IS NOT NULL AND OLD.finalizada IS NULL THEN
    NEW.duracion := EXTRACT(EPOCH FROM (NEW.finalizada - NEW.iniciada))::INT;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calcular_duracion
BEFORE UPDATE ON sesiones
FOR EACH ROW EXECUTE FUNCTION calcular_duracion();
```

**2. Validar que no haya dos sesiones activas simultáneas:**

```sql
CREATE OR REPLACE FUNCTION validar_sesion()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM sesiones WHERE finalizada IS NULL
  ) THEN
    RAISE EXCEPTION 'Ya existe una sesión activa';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sesion_unica
BEFORE INSERT ON sesiones
FOR EACH ROW EXECUTE FUNCTION validar_sesion();
```

### 4.3 RLS + Permisos

```sql
ALTER TABLE grupos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE actividades ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesiones   ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON grupos      TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON actividades TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON sesiones    TO anon;

GRANT USAGE, SELECT ON SEQUENCE grupos_id_seq      TO anon;
GRANT USAGE, SELECT ON SEQUENCE actividades_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE sesiones_id_seq    TO anon;

CREATE POLICY "anon_grupos"      ON grupos      FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_actividades" ON actividades FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_sesiones"    ON sesiones    FOR ALL TO anon USING (true) WITH CHECK (true);
```

### 4.4 Funciones RPC (métricas)

Flutter llama a estas funciones vía `POST /rest/v1/rpc/nombre_funcion`.

**Métrica diaria:**
```sql
CREATE OR REPLACE FUNCTION obtener_metrica_diaria(p_id_actividad INT)
RETURNS JSON LANGUAGE plpgsql AS $$
DECLARE
  v_tz        TEXT      := 'America/Argentina/Buenos_Aires';
  v_hoy       DATE      := (NOW() AT TIME ZONE 'America/Argentina/Buenos_Aires')::DATE;
  v_acumulado INT;
  v_objetivo  INT;
BEGIN
  SELECT COALESCE(SUM(duracion), 0) INTO v_acumulado
  FROM sesiones
  WHERE id_actividad = p_id_actividad
    AND (iniciada AT TIME ZONE v_tz)::DATE = v_hoy;

  SELECT objetivo_diario INTO v_objetivo
  FROM actividades WHERE id = p_id_actividad;

  RETURN json_build_object(
    'acumulado', v_acumulado,
    'restante',  GREATEST(0, COALESCE(v_objetivo, 0) - v_acumulado),
    'excedente', GREATEST(0, v_acumulado - COALESCE(v_objetivo, 0))
  );
END; $$;
```

**Métrica semanal:**
```sql
CREATE OR REPLACE FUNCTION obtener_metrica_semanal(p_id_actividad INT)
RETURNS JSON LANGUAGE plpgsql AS $$
DECLARE
  v_tz             TEXT      := 'America/Argentina/Buenos_Aires';
  v_ahora          TIMESTAMP := NOW() AT TIME ZONE 'America/Argentina/Buenos_Aires';
  v_lunes          DATE      := DATE_TRUNC('week', v_ahora)::DATE;
  v_dia_actual     SMALLINT  := EXTRACT(ISODOW FROM v_ahora)::SMALLINT;
  v_acumulado      INT;
  v_objetivo       INT;
  v_dias           SMALLINT[];
  v_sin_dias       BOOLEAN;
  v_dias_restantes INT;
  v_restante       INT;
BEGIN
  SELECT COALESCE(SUM(duracion), 0) INTO v_acumulado
  FROM sesiones
  WHERE id_actividad = p_id_actividad
    AND (iniciada AT TIME ZONE v_tz)::DATE >= v_lunes;

  SELECT objetivo_semanal, dias INTO v_objetivo, v_dias
  FROM actividades WHERE id = p_id_actividad;

  v_restante := GREATEST(0, COALESCE(v_objetivo, 0) - v_acumulado);
  v_sin_dias := (v_dias IS NULL OR array_length(v_dias, 1) IS NULL);

  IF v_sin_dias THEN
    v_dias_restantes := 8 - v_dia_actual; -- hoy hasta domingo inclusive
  ELSE
    SELECT COUNT(*) INTO v_dias_restantes
    FROM UNNEST(v_dias) d WHERE d >= v_dia_actual;
  END IF;

  RETURN json_build_object(
    'acumulado',                v_acumulado,
    'restante',                 v_restante,
    'excedente',                GREATEST(0, v_acumulado - COALESCE(v_objetivo, 0)),
    'dias_restantes',           v_dias_restantes,
    'sin_dias_asignados',       v_sin_dias,
    'promedio_diario_restante', CASE
                                  WHEN v_dias_restantes = 0 THEN 0
                                  ELSE ROUND(v_restante::NUMERIC / v_dias_restantes)
                                END
  );
END; $$;
```

**Métrica mensual:**
```sql
CREATE OR REPLACE FUNCTION obtener_metrica_mensual(p_id_actividad INT)
RETURNS JSON LANGUAGE plpgsql AS $$
DECLARE
  v_tz                TEXT      := 'America/Argentina/Buenos_Aires';
  v_ahora             TIMESTAMP := NOW() AT TIME ZONE 'America/Argentina/Buenos_Aires';
  v_inicio_mes        DATE      := DATE_TRUNC('month', v_ahora)::DATE;
  v_fin_mes           DATE      := (DATE_TRUNC('month', v_ahora) + INTERVAL '1 month - 1 day')::DATE;
  v_acumulado         INT;
  v_objetivo          INT;
  v_restante          INT;
  v_semanas_restantes NUMERIC;
BEGIN
  SELECT COALESCE(SUM(duracion), 0) INTO v_acumulado
  FROM sesiones
  WHERE id_actividad = p_id_actividad
    AND (iniciada AT TIME ZONE v_tz)::DATE >= v_inicio_mes;

  SELECT objetivo_mensual INTO v_objetivo
  FROM actividades WHERE id = p_id_actividad;

  v_restante          := GREATEST(0, COALESCE(v_objetivo, 0) - v_acumulado);
  v_semanas_restantes := CEIL(((v_fin_mes - v_ahora::DATE) + 1)::NUMERIC / 7);

  RETURN json_build_object(
    'acumulado',                 v_acumulado,
    'restante',                  v_restante,
    'excedente',                 GREATEST(0, v_acumulado - COALESCE(v_objetivo, 0)),
    'semanas_restantes',         v_semanas_restantes,
    'promedio_semanal_restante', CASE
                                   WHEN v_semanas_restantes = 0 THEN 0
                                   ELSE ROUND(v_restante::NUMERIC / v_semanas_restantes)
                                 END
  );
END; $$;
```

**Métrica anual:**
```sql
CREATE OR REPLACE FUNCTION obtener_metrica_anual(p_id_actividad INT)
RETURNS JSON LANGUAGE plpgsql AS $$
DECLARE
  v_tz          TEXT      := 'America/Argentina/Buenos_Aires';
  v_ahora       TIMESTAMP := NOW() AT TIME ZONE 'America/Argentina/Buenos_Aires';
  v_inicio_anio DATE      := DATE_TRUNC('year', v_ahora)::DATE;
  v_acumulado   INT;
  v_objetivo    INT;
BEGIN
  SELECT COALESCE(SUM(duracion), 0) INTO v_acumulado
  FROM sesiones
  WHERE id_actividad = p_id_actividad
    AND (iniciada AT TIME ZONE v_tz)::DATE >= v_inicio_anio;

  SELECT objetivo_anual INTO v_objetivo
  FROM actividades WHERE id = p_id_actividad;

  RETURN json_build_object(
    'acumulado', v_acumulado,
    'restante',  GREATEST(0, COALESCE(v_objetivo, 0) - v_acumulado),
    'excedente', GREATEST(0, v_acumulado - COALESCE(v_objetivo, 0))
  );
END; $$;
```

**Resumen dashboard (todas las actividades):**
```sql
CREATE OR REPLACE FUNCTION obtener_resumen()
RETURNS JSON LANGUAGE plpgsql AS $$
DECLARE
  v_tz         TEXT      := 'America/Argentina/Buenos_Aires';
  v_ahora      TIMESTAMP := NOW() AT TIME ZONE 'America/Argentina/Buenos_Aires';
  v_hoy        DATE      := v_ahora::DATE;
  v_lunes      DATE      := DATE_TRUNC('week', v_ahora)::DATE;
  v_dia_actual SMALLINT  := EXTRACT(ISODOW FROM v_ahora)::SMALLINT;
BEGIN
  RETURN (
    SELECT json_agg(json_build_object(
      'id',              a.id,
      'nombre',          a.nombre,
      'color',           a.color,
      'objetivo_diario', a.objetivo_diario,
      'acumulado_hoy',   COALESCE(hoy.total, 0),
      'restante_hoy',    GREATEST(0, COALESCE(a.objetivo_diario, 0) - COALESCE(hoy.total, 0)),
      'excedente_hoy',   GREATEST(0, COALESCE(hoy.total, 0) - COALESCE(a.objetivo_diario, 0)),
      'acumulado_semana',  COALESCE(sem.total, 0),
      'restante_semanal',  GREATEST(0, COALESCE(a.objetivo_semanal, 0) - COALESCE(sem.total, 0)),
      'sin_dias_asignados', (a.dias IS NULL OR array_length(a.dias, 1) IS NULL),
      'promedio_diario_restante_semana',
        CASE
          WHEN (a.dias IS NULL OR array_length(a.dias, 1) IS NULL) THEN
            ROUND(
              GREATEST(0, COALESCE(a.objetivo_semanal, 0) - COALESCE(sem.total, 0))::NUMERIC
              / GREATEST(1, 8 - v_dia_actual)
            )
          WHEN (SELECT COUNT(*) FROM UNNEST(a.dias) d WHERE d >= v_dia_actual) = 0 THEN 0
          ELSE
            ROUND(
              GREATEST(0, COALESCE(a.objetivo_semanal, 0) - COALESCE(sem.total, 0))::NUMERIC
              / (SELECT COUNT(*) FROM UNNEST(a.dias) d WHERE d >= v_dia_actual)
            )
        END
    ))
    FROM actividades a
    LEFT JOIN (
      SELECT id_actividad, SUM(duracion)::INT AS total
      FROM sesiones
      WHERE (iniciada AT TIME ZONE v_tz)::DATE = v_hoy
      GROUP BY id_actividad
    ) hoy ON hoy.id_actividad = a.id
    LEFT JOIN (
      SELECT id_actividad, SUM(duracion)::INT AS total
      FROM sesiones
      WHERE (iniciada AT TIME ZONE v_tz)::DATE >= v_lunes
      GROUP BY id_actividad
    ) sem ON sem.id_actividad = a.id
  );
END; $$;
```

**Permisos de ejecución:**
```sql
GRANT EXECUTE ON FUNCTION obtener_metrica_diaria(INT) TO anon;
GRANT EXECUTE ON FUNCTION obtener_metrica_semanal(INT) TO anon;
GRANT EXECUTE ON FUNCTION obtener_metrica_mensual(INT) TO anon;
GRANT EXECUTE ON FUNCTION obtener_metrica_anual(INT) TO anon;
GRANT EXECUTE ON FUNCTION obtener_resumen() TO anon;
```

### 4.5 Procedimientos Almacenados (SP)

**`iniciar_sesion(p_id_actividad)`** — cierra la sesión activa (si existe) y abre una nueva en una sola transacción atómica. Evita inconsistencia si el usuario cambia de actividad sin pausar primero.

```sql
CREATE OR REPLACE PROCEDURE iniciar_sesion(p_id_actividad INT)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE sesiones
  SET finalizada = NOW()
  WHERE finalizada IS NULL;

  INSERT INTO sesiones (id_actividad, iniciada)
  VALUES (p_id_actividad, NOW());
END; $$;

GRANT EXECUTE ON PROCEDURE iniciar_sesion(INT) TO anon;
```

Flutter llama: `POST /rest/v1/rpc/iniciar_sesion` con `{"p_id_actividad": 2}`.
El trigger `calcular_duracion` se dispara automáticamente sobre el UPDATE.

> Para pausar, CRUD de actividades y grupos una sola llamada REST es suficiente — no justifican SP.

---

## 5. Modelo de Sesiones (cronómetro)

Cada intervalo **play → pause** genera una fila en `sesiones`.

```
PLAY   → INSERT sesion (iniciada = now(), finalizada = NULL)
PAUSE  → UPDATE sesion SET finalizada = now()   ← trigger calcula duracion
RESUME → INSERT sesion nueva (iniciada = now())
STOP   → igual que PAUSE
```

Flutter suma todas las `duracion` de una misma actividad para los reportes (vía RPC).

**Ejemplo — Actividad "Lectura", martes:**
```
sesion 1: 10:00 → 10:20  (duracion = 1200)
sesion 2: 11:00 → 11:30  (duracion = 1800)
sesion 3: 14:00 → 14:10  (duracion =  600)
Total del día = 3600 seg = 60 min
```

---

## 6. Lógica de Métricas

> Lógica más importante de la app. El cronómetro descuenta tiempo en cascada: **diario → semanal → mensual → anual**.

### 6.1 Concepto general

Al iniciar una actividad, la pantalla muestra cuánto **falta** para el objetivo. Si me detengo a mitad, al continuar aparece el remanente. Cuando completo el objetivo diario y sigo, el excedente comienza a descontar del **semanal**. Al iniciar el siguiente día, vuelve a descontar el objetivo de ese día.

### 6.2 Diario

```
restante_hoy  = MAX(0, objetivo_diario - acumulado_hoy)
excedente_hoy = MAX(0, acumulado_hoy - objetivo_diario)
```

Mutuamente excluyentes. Nunca negativos.

### 6.3 Semanal

```
restante_semanal = MAX(0, objetivo_semanal - acumulado_semana)
dias_restantes   = días configurados en dias[] >= hoy (o hoy→domingo si dias[] vacío)
promedio_diario_restante = restante_semanal / dias_restantes
```

> Ejemplo: obj_semanal=300, miércoles acumuló 90 min (60 + 30 extra).
> restante=210, días restantes=jue,vie,sáb=3 → promedio=**70 min/día**.

### 6.4 Mensual

```
restante_mensual         = MAX(0, objetivo_mensual - acumulado_mes)
semanas_restantes        = CEIL(días_hasta_fin_de_mes / 7)
promedio_semanal_restante = restante_mensual / semanas_restantes
```

### 6.5 Anual

```
restante_anual = MAX(0, objetivo_anual - acumulado_anio)
```

### 6.6 Casos borde

**A) `actividad.dias` vacío:**
- `dias_restantes` = días desde hoy hasta domingo inclusive.
- Flutter muestra cartel NO bloqueante:
  > ⚠️ Esta actividad no tiene días asignados. El promedio semanal se calcula distribuyendo el tiempo restante entre hoy y el domingo, hasta que asignes días.

**B) `actividad.dias` definido y sin días restantes en la semana:**
- `dias_restantes = 0` → `promedio = 0` → objetivo cumplido (no es error).

---

## 7. Llamadas Supabase desde Flutter

### CRUD directo (REST)

```
GET    /rest/v1/grupos
POST   /rest/v1/grupos
PATCH  /rest/v1/grupos?id=eq.{id}
DELETE /rest/v1/grupos?id=eq.{id}

GET    /rest/v1/actividades
POST   /rest/v1/actividades
PATCH  /rest/v1/actividades?id=eq.{id}
DELETE /rest/v1/actividades?id=eq.{id}
```

### Sesiones

```
POST   /rest/v1/sesiones              ← play (body: {id_actividad, iniciada})
PATCH  /rest/v1/sesiones?id=eq.{id}  ← pause/stop (body: {finalizada})
GET    /rest/v1/sesiones?finalizada=is.null  ← sesión activa
```

### Métricas (RPC)

```
POST   /rest/v1/rpc/obtener_metrica_diaria    body: {"p_id_actividad": 1}
POST   /rest/v1/rpc/obtener_metrica_semanal   body: {"p_id_actividad": 1}
POST   /rest/v1/rpc/obtener_metrica_mensual   body: {"p_id_actividad": 1}
POST   /rest/v1/rpc/obtener_metrica_anual     body: {"p_id_actividad": 1}
POST   /rest/v1/rpc/obtener_resumen           body: {}
```

---

## 8. Estructura de Carpetas

```
track-time/
└── lib/
    ├── pantallas/
    │   ├── inicio/
    │   ├── actividades/
    │   ├── cronometro/
    │   └── metricas/
    ├── componentes/
    ├── servicios/
    │   └── supabase.dart       ← cliente HTTP, anon key, todas las llamadas REST/RPC
    ├── modelos/
    │   ├── grupo.dart
    │   ├── actividad.dart
    │   └── sesion.dart
    └── constantes/
        └── colores.dart
```

La `anon key` y la URL de Supabase viven en `supabase.dart` (o en un `.env` cargado con `flutter_dotenv`, gitignoreado).

---

## 9. Pantallas Flutter (UI / Navegación)

### Bottom Navigation Bar (parte inferior)

```
├── Inicio          (izquierda)
├── [+] Cronómetro  (centro, botón elevado)
└── Actividades     (derecha)
```

### Métricas
- No entra en el navigation bar.
- Botón pequeño **arriba a la izquierda** desde Inicio.

### Detalle por pantalla

**Inicio**
- Dashboard: resumen diario de todas las actividades (vía `obtener_resumen`).
- Progreso visual + cuánto falta para el objetivo diario.
- Sesión activa si existe.
- Botón métricas (arriba izquierda).

**Cronómetro** (pantalla propia desde botón central)
- Seleccionar actividad → Play / Pause / Stop.
- Muestra `restante_hoy` y `promedio_diario_restante` en tiempo real.

**Actividades**
- Lista agrupada por grupo.
- Crear/editar actividad: nombre, color (elegible), días, meses, objetivos (diario, semanal, mensual, anual).
- Crear/editar/eliminar grupo dentro de esta misma sección.
- Eliminar actividad.

**Métricas**
- Vista diaria / semanal / mensual / anual.
- Por actividad, seleccionable.

---

## 11. Diseño Visual

### 11.1 Paleta de colores — modo oscuro único

| Token | Hex | Uso |
|---|---|---|
| bg-pantalla | #1E1E21 | Fondo de todas las pantallas |
| bg-card | #2E2E33 | Cards y surfaces sobre el fondo |
| bg-elevado | #55544F | Modals, chips seleccionados, estados activos |
| texto-primario | #EDECE8 | Texto principal |
| texto-secundario | #9A9890 | Labels, subtítulos |
| inactivo | #55544F | Iconos y texto inactivos |
| acento | #9DD929 | Ring timer, botones activos, tab seleccionado |

### 11.2 Colores de actividades

Set fijo de 8 opciones que el usuario elige al crear una actividad:

| Nombre | Hex |
|---|---|
| Rojo | #E05840 |
| Naranja | #E88A20 |
| Amarillo | #D4B030 |
| Verde | #4CB870 |
| Teal | #27B89A |
| Azul | #4A90E8 |
| Violeta | #6D14CC |
| Rosa | #B715D4 |

### 11.3 Tipografía

Fuente del sistema del dispositivo. En Flutter: `Theme.of(context).textTheme` sin override de `fontFamily`.

### 11.3 Logo y splash screen

- **Logo:** cronómetro con líneas de velocidad (estilo outline/flat)
- **Aparece:** solo en el splash screen, antes de abrir la app — no se usa en ninguna pantalla interna
- **Color en splash:** `#EDECE8` (blanco cálido) sobre fondo `#1E1E21`
- **Asset:** guardar en `assets/imagenes/logo.png` (y `.svg` si se dispone del vector)
- **Implementación:** paquete `flutter_native_splash` con `background_color: #1E1E21`

### 11.4 Decisiones de UI

**Dashboard (Inicio):**
- Progreso diario por actividad: gráfico **donut/anillo**
- Actividad sin objetivo diario: muestra solo el tiempo acumulado, sin anillo

**Cronómetro:**
- Formato de tiempo: `HH:MM:SS`
- Anillo de progreso hacia el objetivo diario de la actividad

**Sesión activa:**
- Indicador: barra horizontal delgada del **color de la actividad** en el top de cualquier pantalla mientras haya una sesión corriendo

---

## 10. Resumen de Decisiones Confirmadas

| Tema | Decisión |
|---|---|
| Plataforma | App móvil Flutter |
| Usuario | Único, sin auth |
| Comunicación | Flutter → Supabase REST + RPC directo |
| Acceso BD | `anon key` + RLS |
| Backend Java | Eliminado |
| IDs | `SERIAL` (no UUID) |
| Color de actividad | Elegible por el usuario al crear |
| Objetivos | Diario, semanal, mensual, anual |
| Días/meses de actividad | Arrays opcionales, guía organizativa |
| Timezone | Argentina UTC−3 (`America/Argentina/Buenos_Aires`) |
| Semana | Lunes a Domingo (ISODOW) |
| Duración | Calculada por trigger al pausar |
| Sesión única | Validada por trigger |
| Lógica métricas | Funciones RPC PostgreSQL |
| Deploy | No aplica (sin servidor) |
