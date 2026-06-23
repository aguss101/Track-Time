import 'package:flutter/services.dart';

/// Puente Flutter ↔ Android para el foreground service del cronómetro.
///
/// Mientras hay una sesión activa, Android mantiene una notificación
/// persistente que cuenta el tiempo aunque la app esté en segundo plano.
/// El servicio nativo vive en `android/.../CronometroService.java`.
class CronometroNativo {
  CronometroNativo._();
  static final CronometroNativo instancia = CronometroNativo._();

  static const MethodChannel _canal =
      MethodChannel('com.agustin.track_time/cronometro');

  /// Arranca el foreground service con la notificación persistente.
  /// [iniciadaMillis] es el epoch en ms del inicio real de la sesión, para que
  /// la notificación cuente desde el momento correcto aunque se reanude.
  Future<void> iniciar({
    required String nombreActividad,
    required String colorHex,
    required int iniciadaMillis,
  }) async {
    try {
      await _canal.invokeMethod('iniciar', {
        'nombre': nombreActividad,
        'color': colorHex,
        'iniciada': iniciadaMillis,
      });
    } on PlatformException catch (_) {
      // En un dispositivo sin el servicio (o en tests) no rompemos la app:
      // el cronómetro en pantalla sigue funcionando igual.
    } on MissingPluginException catch (_) {}
  }

  /// Detiene el foreground service y quita la notificación.
  Future<void> detener() async {
    try {
      await _canal.invokeMethod('detener');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }
}
