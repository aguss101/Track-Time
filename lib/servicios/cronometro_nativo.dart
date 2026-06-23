import 'package:flutter/services.dart';

class CronometroNativo {
  CronometroNativo._();
  static final CronometroNativo instancia = CronometroNativo._();

  static const MethodChannel _canal =
      MethodChannel('com.agustin.track_time/cronometro');

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
    } on MissingPluginException catch (_) {}
  }

  Future<void> detener() async {
    try {
      await _canal.invokeMethod('detener');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }
}
