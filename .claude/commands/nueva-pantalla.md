---
description: Scaffoldea una nueva pantalla Flutter en lib/pantallas/ siguiendo las convenciones del proyecto
---

Crea la pantalla `$ARGUMENTS` en `lib/pantallas/$ARGUMENTS/$ARGUMENTS.dart`.

Convenciones obligatorias:
- Nombre de clase en PascalCase + sufijo `Page`: ej. `cronometro` → `CronometroPage`
- Sin sufijo redundante en el nombre de archivo
- `Scaffold(backgroundColor: const Color(0xFF1E1E21))` como raíz
- Envolver el contenido en `SafeArea`
- Usar `Theme.of(context).textTheme` para tipografía — sin fuente custom
- Importar colores desde `package:track_time/constantes/colores.dart`
- No agregar routing ni navegación — eso se define por separado

Si el argumento incluye una descripción de qué debe hacer la pantalla, scaffoldea con la estructura básica de widgets correspondiente. De lo contrario, crear el boilerplate mínimo.
