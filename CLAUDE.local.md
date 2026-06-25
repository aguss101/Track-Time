# Notas locales — no se commitea

## Entorno
- OS: Windows 10 Pro
- IDE: VS Code
- Shell: PowerShell (primario)
- Emulador Android configurado localmente en VS Code

## Variables sensibles
- Credenciales Supabase (`SUPABASE_URL`, `SUPABASE_KEY` = anon public) van en `env.json` (raíz del proyecto, gitignoreado).
- Se inyectan en compilación con `--dart-define-from-file=env.json` y se leen en Dart con `String.fromEnvironment`. NO se hardcodean en `supabase.dart`.

## Preferencias de desarrollo
- Branch de trabajo: `dev--`
- Merge a `main` cuando la feature esté lista y probada en dispositivo
- Solo un desarrollador en el proyecto (Agustin)

## Aviso al terminar tareas
Configurado como hook global `Stop` en `~/.claude/settings.json` (aplica a todos los proyectos): `curl -s -o /dev/null -d 'Claudio acabó' ntfy.sh/claude_respuesta`. No requiere acción manual.
