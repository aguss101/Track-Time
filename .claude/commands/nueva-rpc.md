---
description: Agrega un método de llamada RPC o SP de Supabase en lib/servicios/supabase.dart
---

Agrega el método `$ARGUMENTS` en `lib/servicios/supabase.dart` para llamar al endpoint `POST /rest/v1/rpc/$ARGUMENTS`.

Patrón obligatorio:
```dart
Future<Map<String, dynamic>> $ARGUMENTS({parámetros requeridos}) async {
  final response = await http.post(
    Uri.parse('$_url/rest/v1/rpc/$ARGUMENTS'),
    headers: _headers,
    body: jsonEncode({/* parámetros */}),
  );
  if (response.statusCode != 200) {
    throw Exception('Error en $ARGUMENTS: ${response.statusCode} ${response.body}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

Revisar `PROYECTO.md` sección 4.4 para los parámetros exactos de la función RPC correspondiente.
Si es un SP (como `iniciar_sesion`), el return type puede ser `Future<void>` y verificar statusCode 204.
