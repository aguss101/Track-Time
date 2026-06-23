# Track-Time — Guía para Claude

> Spec completa en `PROYECTO.md`. Este archivo es la referencia operacional rápida.

## Qué es
App móvil Flutter personal de tracking de tiempo de estudio/trabajo. Usuario único, sin auth, sin backend. Flutter habla directamente con Supabase REST + RPC.

## Stack
Flutter (Dart) · Riverpod (estado) · Android + MethodChannel (foreground service en **Kotlin**) · Supabase REST+RPC (sin SDK) · anon key + RLS · VS Code

> Nota: el servicio nativo se implementó en **Kotlin**, no Java. `flutter create` scaffoldea `MainActivity.kt` en Kotlin; mezclar Java hubiera sumado fricción de build sin beneficio. La spec original decía "Java" — desviación consciente.

## Convenciones — aplicar siempre
- Idioma: **español** en todo (archivos, carpetas, clases, variables, funciones, DB, comentarios)
- Sin sufijo redundante: `pantallas/inicio/inicio.dart` ✓ — `pantalla_inicio.dart` ✗
- Timezone: `America/Argentina/Buenos_Aires` en toda lógica de fechas
- Semana: ISODOW (lunes=1, domingo=7)
- IDs: `SERIAL` — no UUID
- Tipografía: `Theme.of(context).textTheme` — sin override de fuente (usa la del sistema)
- **Sin comentarios en el código** — ni de bloque ni de línea. Los nombres de variables/funciones deben ser suficientemente descriptivos.

## Estructura `lib/` (real)
```
lib/
├── main.dart                    ← ProviderScope + tema + SplashPage
├── constantes/colores.dart  tema.dart
├── modelos/grupo.dart  actividad.dart  sesion.dart  resumen.dart  metrica.dart
├── servicios/
│   ├── supabase.dart            ← única clase que toca HTTP (singleton)
│   └── cronometro_nativo.dart   ← MethodChannel → foreground service
├── estado/                      ← Riverpod
│   ├── proveedores.dart         ← supabase, grupos, actividades, resumen
│   ├── sesion_activa.dart       ← Notifier con timer en vivo + servicio nativo
│   └── metricas.dart            ← FutureProvider.family por actividad
├── util/formato.dart            ← HH:MM:SS y duraciones compactas
├── componentes/anillo_progreso.dart  barra_sesion_activa.dart  selector_color.dart
└── pantallas/
    ├── splash/splash.dart
    ├── shell.dart               ← bottom nav + IndexedStack
    ├── inicio/inicio.dart
    ├── cronometro/cronometro.dart
    ├── actividades/actividades.dart  formulario_actividad.dart  gestion_grupos.dart
    └── metricas/metricas.dart
```

## Para correr
1. Credenciales: crear `env.json` en la raíz con `SUPABASE_URL` y `SUPABASE_KEY` (anon public). `env.json` está gitignoreado.
2. `flutter pub get`.
3. Correr inyectando las credenciales:
   `flutter run --dart-define-from-file=env.json` (en VS Code, F5 ya lo hace vía `.vscode/launch.json`).
4. Splash nativo: regenerar con `dart run flutter_native_splash:create` si cambia el color.

> Las credenciales NO van hardcodeadas en `supabase.dart`: se leen con `String.fromEnvironment`. Si faltan, `Supabase.verificarCredenciales()` en `main()` corta con un mensaje claro.

## Supabase — patrón de llamada (HTTP directo, sin SDK)
```dart
static const _headers = {
  'apikey': _anonKey,
  'Authorization': 'Bearer $_anonKey',
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
};

// CRUD
await http.get(Uri.parse('$_url/rest/v1/actividades'), headers: _headers);
await http.patch(
  Uri.parse('$_url/rest/v1/sesiones?id=eq.$id'),
  headers: _headers,
  body: jsonEncode({'finalizada': isoTimestamp}),
);

// RPC
await http.post(
  Uri.parse('$_url/rest/v1/rpc/obtener_resumen'),
  headers: _headers,
  body: jsonEncode({}),
);

// SP (atómico)
await http.post(
  Uri.parse('$_url/rest/v1/rpc/iniciar_sesion'),
  headers: _headers,
  body: jsonEncode({'p_id_actividad': id}),
);
```

## Diseño — modo oscuro único
| Token | Hex | Uso |
|---|---|---|
| bg-pantalla | #1E1E21 | Fondo de todas las pantallas |
| bg-card | #2E2E33 | Cards, surfaces sobre el fondo |
| bg-elevado | #55544F | Modals, chips seleccionados, estados activos |
| texto-primario | #EDECE8 | |
| texto-secundario | #9A9890 | |
| inactivo | #55544F | Iconos/texto inactivos |
| acento | #9DD929 | Ring timer, botones activos, tab seleccionado |

**Colores de actividades (set fijo de 8, usuario elige uno):**
`#E05840` Rojo · `#E88A20` Naranja · `#D4B030` Amarillo · `#4CB870` Verde · `#27B89A` Teal · `#4A90E8` Azul · `#6D14CC` Violeta · `#B715D4` Rosa

**Logo:** cronómetro con líneas de velocidad — solo en splash screen, nunca dentro de la app. Asset en `assets/imagenes/logo.svg`. Color `#EDECE8` sobre fondo `#1E1E21`. Implementar con `flutter_native_splash`.

**UI decisions confirmadas:**
- Timer: formato `HH:MM:SS` + anillo de progreso hacia el objetivo diario
- Dashboard (Inicio): donut/anillo por actividad
- Sin objetivo diario → mostrar solo tiempo acumulado, sin anillo
- Sesión activa: barra horizontal delgada del color de la actividad en top de pantalla
- Bottom nav: `Inicio` | `[+] Cronómetro` (FAB elevado, centro) | `Actividades`
- Métricas: botón pequeño arriba-izquierda desde Inicio — no va en el nav

## DB — tablas
- `grupos(id SERIAL PK, nombre TEXT, color TEXT)`
- `actividades(id, id_grupo FK→grupos, nombre, color, dias SMALLINT[], meses SMALLINT[], objetivo_diario/semanal/mensual/anual INT, creado TIMESTAMPTZ)`
- `sesiones(id, id_actividad FK→actividades CASCADE, iniciada TIMESTAMPTZ, finalizada TIMESTAMPTZ, duracion INT)`

**Triggers:**
- `calcular_duracion` → calcula `duracion` al hacer UPDATE SET finalizada
- `sesion_unica` → bloquea dos sesiones activas simultáneas

## DB — funciones RPC
`obtener_resumen()` · `obtener_metrica_diaria(INT)` · `obtener_metrica_semanal(INT)` · `obtener_metrica_mensual(INT)` · `obtener_metrica_anual(INT)`

**SP:** `iniciar_sesion(INT)` — cierra sesión activa si existe y abre nueva, en una sola transacción

## Slash commands disponibles
- `/nueva-pantalla [nombre]` — scaffoldea una pantalla en `lib/pantallas/`
- `/nueva-rpc [nombre]` — agrega método de llamada RPC en `servicios/supabase.dart`

## PROHIBIDO
UUID · Supabase SDK · Edge Functions · Backend Java · Auth/login · service_role key · sufijos redundantes en archivos · fuente custom · tabla `actividad_dias`
