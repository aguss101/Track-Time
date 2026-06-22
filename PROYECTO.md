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
| Backend | Java + Spring Boot — paquete `com.tracktime` |
| Base de datos | Supabase (acceso vía **API REST**, no SDK) |
| Auth a Supabase | `service_role key` en el backend (en `.env`, **nunca** en el frontend) |
| IDE | VS Code |
| Deploy | Pendiente, **post-desarrollo** (sugerido: Oracle Cloud Free Tier, 24/7 gratis sin sleep) |

### Arquitectura de comunicación (Opción A — confirmada)

```
Flutter → HTTP → Java API → Supabase REST
```

El frontend **nunca** toca Supabase directamente. Todo pasa por la API Java. Único punto de control, credenciales solo en backend, frontend desacoplado de la BD.

### Decisiones descartadas (no implementar)

- ❌ **UUID** → se usa `SERIAL` (IDs secuenciales).
- ❌ **Edge Functions** → la lógica de métricas vive en Java.
- ❌ **Supabase Auth / login / registro** → usuario único.
- ❌ **Tabla `actividad_dias`** → reemplazada por columna array `dias`.
- ❌ **Claude Design** → no aplica (app móvil Flutter, no web).
- ❌ **Flutter hablando directo con Supabase** → siempre vía backend Java.

---

## 3. Convenciones

- **Idioma**: schema, carpetas, archivos y funciones en **español**.
- **Nombres de archivo sin sufijo redundante**: un archivo dentro de `controladores/` se llama `Actividad.java`, no `ActividadControlador.java`. Aplica a toda la estructura.
- **Timezone**: Argentina (UTC−3) fijo.
- **Semana**: Lunes a Domingo.

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

---

## 5. Modelo de Sesiones (cronómetro)

Cada intervalo **play → pause** genera una fila en `sesiones`.

```
PLAY   → INSERT sesion (iniciada = now(), finalizada = NULL)
PAUSE  → UPDATE sesion SET finalizada = now()   ← trigger calcula duracion
RESUME → INSERT sesion nueva (iniciada = now())
STOP   → igual que PAUSE
```

El backend suma todas las `duracion` de una misma actividad para los reportes.

**Ejemplo — Actividad "Lectura", martes:**
```
sesion 1: 10:00 → 10:20  (duracion = 1200)
sesion 2: 11:00 → 11:30  (duracion = 1800)
sesion 3: 14:00 → 14:10  (duracion =  600)
Total del día = 3600 seg = 60 min
```

---

## 6. Lógica de Métricas (núcleo del backend)

> Esta es la lógica más importante de la app. El cronómetro descuenta tiempo de los objetivos en cascada: **diario → semanal → mensual → anual**.

### 6.1 Concepto general

Al iniciar una actividad, la pantalla muestra cuánto **falta** para el objetivo. Si me detengo a mitad, al continuar aparece el remanente. Cuando completo el objetivo diario y sigo, el excedente comienza a descontar del **semanal**, y así sucesivamente. Al iniciar el siguiente día, vuelve a descontar el objetivo de ese día.

### 6.2 Diario

```
acumulado_hoy = SUM(duracion) WHERE id_actividad = X
                AND DATE(iniciada) = hoy (UTC−3)

restante_hoy  = MAX(0, objetivo_diario - acumulado_hoy)
excedente_hoy = MAX(0, acumulado_hoy - objetivo_diario)
```

`restante_hoy` y `excedente_hoy` son **mutuamente excluyentes**: gracias a `MAX(0, …)` nunca dan negativo, y mientras uno tiene valor el otro es 0.

### 6.3 Semanal (promedio por días restantes)

```
acumulado_semana = SUM(duracion) WHERE id_actividad = X
                   AND iniciada >= lunes_actual (UTC−3)

restante_semanal = MAX(0, objetivo_semanal - acumulado_semana)

dias_restantes   = días configurados en actividad.dias que sean > hoy
                   en la semana actual

promedio_diario_restante_semana = restante_semanal / dias_restantes
```

**Comportamiento clave:** si hago de más un día, el promedio de los días restantes baja (se recalcula sobre el remanente).

> Ejemplo: objetivo_semanal = 300 min (5 h), días = lun, mié, jue, vie, sáb.
> El miércoles hago 60 + 30 extra = 90 min acumulados en la semana.
> restante_semanal = 210 min. Días restantes = jue, vie, sáb = 3.
> promedio = 210 / 3 = **70 min/día**.

### 6.4 Mensual (mismo patrón, por semanas)

```
acumulado_mes     = SUM(duracion) WHERE id_actividad = X
                    AND MONTH(iniciada) = mes_actual (UTC−3)

restante_mensual  = MAX(0, objetivo_mensual - acumulado_mes)

semanas_restantes = semanas que quedan hasta fin de mes

promedio_semanal_restante = restante_mensual / semanas_restantes
```

### 6.5 Anual

Acumulado del año vs `objetivo_anual`. Restante con `MAX(0, …)`.

### 6.6 Casos borde y manejo de errores

**A) Actividad SIN días asignados (`actividad.dias` vacío):**
- `dias_restantes` = días corridos desde hoy hasta domingo inclusive.
  (Si hoy es miércoles → [mié, jue, vie, sáb, dom] = 5 días.)
- Mostrar **cartel informativo NO bloqueante**:
  > ⚠️ Esta actividad no tiene días asignados. El promedio semanal/mensual se calcula distribuyendo el tiempo restante entre hoy y el domingo, hasta que asignes días.

**B) Actividad CON días asignados y ninguno queda en la semana:**
- `dias_restantes` = 0 → `promedio = 0` → **objetivo cumplido** (no es error).

> Ejemplo: viernes, días configurados ya pasados → promedio = 0, objetivo cumplido.
> Ejemplo: viernes sin días configurados → [vie, sáb, dom] = 3 días → promedio normal.

---

## 7. API REST (Java)

### Grupos
```
GET    /grupos
POST   /grupos
PUT    /grupos/{id}
DELETE /grupos/{id}
```

### Actividades
```
GET    /actividades
GET    /actividades/{id}
POST   /actividades
PUT    /actividades/{id}
DELETE /actividades/{id}
```

### Sesiones
```
POST   /sesiones/iniciar/{id_actividad}   ← play
PATCH  /sesiones/pausar/{id_sesion}       ← pause / stop
GET    /sesiones/activa                    ← consultar sesión en curso
```

### Métricas
```
GET    /metricas/{id_actividad}/diario
GET    /metricas/{id_actividad}/semanal
GET    /metricas/{id_actividad}/mensual
GET    /metricas/{id_actividad}/anual
GET    /metricas/resumen                   ← todas las actividades para dashboard
```

**Forma de `/metricas/resumen` (por actividad):**
```json
{
  "id": 1,
  "nombre": "Lectura",
  "color": "#4A90D9",
  "objetivo_diario": 60,
  "acumulado_hoy": 20,
  "restante_hoy": 40,
  "promedio_diario_restante_semana": 70
}
```

---

## 8. Estructura de Carpetas

```
track-time/
├── backend/
│   └── src/main/java/com/tracktime/
│       ├── controladores/
│       │   ├── Grupo.java
│       │   ├── Actividad.java
│       │   ├── Sesion.java
│       │   └── Metrica.java
│       ├── servicios/
│       │   ├── Grupo.java
│       │   ├── Actividad.java
│       │   ├── Sesion.java
│       │   └── Metrica.java
│       ├── modelos/
│       │   ├── Grupo.java
│       │   ├── Actividad.java
│       │   └── Sesion.java
│       ├── repositorios/
│       │   ├── Grupo.java
│       │   ├── Actividad.java
│       │   └── Sesion.java
│       └── configuracion/
│           └── Supabase.java
│   └── src/main/resources/
│       └── application.properties
│
└── frontend/
    └── lib/
        ├── pantallas/
        │   ├── inicio/
        │   ├── actividades/
        │   ├── cronometro/
        │   └── metricas/
        ├── componentes/
        ├── servicios/
        │   └── api.dart
        ├── modelos/
        │   ├── grupo.dart
        │   ├── actividad.dart
        │   └── sesion.dart
        └── constantes/
            └── colores.dart
```

---

## 9. Pantallas Flutter (UI / Navegación)

### Bottom Navigation Bar (parte inferior)
```
├── Inicio          (izquierda)
├── [+] Cronómetro  (centro, botón elevado)
└── Actividades     (derecha)
```

### Métricas
- **No** entra en el navigation bar.
- Botón pequeño **arriba a la izquierda** (desde Inicio) que abre las métricas.

### Detalle por pantalla

**Inicio**
- Dashboard: resumen diario de todas las actividades.
- Progreso visual + indicador de cuánto falta para el objetivo diario.
- Muestra la sesión activa si existe.
- Botón métricas (arriba izquierda).

**Cronómetro** (pantalla propia, abierta desde botón central; también accesible)
- Seleccionar actividad → Play / Pause / Stop.
- Muestra `restante_hoy` y promedio semanal en tiempo real.

**Actividades**
- Lista de actividades agrupadas por grupo.
- Crear/editar actividad: nombre, **color elegible al crear**, días, meses, objetivos (diario, semanal, mensual, anual).
- Crear/editar grupo: nombre, color. **Los grupos se gestionan dentro de Actividades** (no tienen sección propia).
- Eliminar actividad / grupo.

**Métricas**
- Vista diaria.
- Vista semanal.
- Vista mensual.
- Vista anual.
- Por actividad, seleccionable.

---

## 10. Resumen de Decisiones Confirmadas

| Tema | Decisión |
|---|---|
| Plataforma | App móvil (Flutter) |
| Usuario | Único, sin auth |
| Comunicación | Flutter → Java API → Supabase REST |
| Acceso BD | `service_role key` en backend |
| IDs | `SERIAL` (no UUID) |
| Color de actividad | Elegible por el usuario al crear |
| Objetivos | Diario, semanal, mensual, anual |
| Días/meses de actividad | Arrays opcionales, guía organizativa |
| Timezone | Argentina UTC−3 |
| Semana | Lunes a Domingo |
| Duración | Calculada por trigger al pausar |
| Sesión única | Validada por trigger (no dos activas) |
| Lógica métricas | En Java (no Edge Functions) |
| Deploy | Post-desarrollo (sugerido Oracle Cloud Free Tier) |
| Paquete Java | `com.tracktime` |
```
