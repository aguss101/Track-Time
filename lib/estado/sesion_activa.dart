import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/actividad.dart';
import '../modelos/sesion.dart';
import '../servicios/cronometro_nativo.dart';
import 'metricas.dart';
import 'proveedores.dart';

class SesionActivaEstado {
  final Sesion? sesion;
  final Actividad? actividad;
  final int transcurridos;

  const SesionActivaEstado({
    this.sesion,
    this.actividad,
    this.transcurridos = 0,
  });

  bool get hayActiva => sesion != null && actividad != null;

  SesionActivaEstado copyWith({
    Sesion? sesion,
    Actividad? actividad,
    int? transcurridos,
  }) {
    return SesionActivaEstado(
      sesion: sesion ?? this.sesion,
      actividad: actividad ?? this.actividad,
      transcurridos: transcurridos ?? this.transcurridos,
    );
  }

  static const vacio = SesionActivaEstado();
}

final sesionActivaProvider =
    NotifierProvider<SesionActivaNotifier, SesionActivaEstado>(
        SesionActivaNotifier.new);

class SesionActivaNotifier extends Notifier<SesionActivaEstado> {
  Timer? _timer;

  @override
  SesionActivaEstado build() {
    ref.onDispose(() => _timer?.cancel());
    _recuperar();
    return SesionActivaEstado.vacio;
  }

  Future<void> iniciar(Actividad actividad) async {
    final db = ref.read(supabaseProvider);
    await db.iniciarSesion(actividad.id);
    final sesion = await db.sesionActiva();
    if (sesion == null) return;

    state = SesionActivaEstado(
      sesion: sesion,
      actividad: actividad,
      transcurridos: sesion.transcurridos(),
    );
    _arrancarTimer();

    await CronometroNativo.instancia.iniciar(
      nombreActividad: actividad.nombre,
      colorHex: actividad.color,
      iniciadaMillis: sesion.iniciada.millisecondsSinceEpoch,
    );

    ref.invalidate(resumenProvider);
    ref.invalidate(metricasProvider(actividad.id));
  }

  Future<void> pausar() async {
    final sesion = state.sesion;
    if (sesion == null) return;

    _timer?.cancel();
    await ref.read(supabaseProvider).pausarSesion(sesion.id);
    await CronometroNativo.instancia.detener();

    ref.invalidate(resumenProvider);
    ref.invalidate(metricasProvider(sesion.idActividad));
    state = SesionActivaEstado.vacio;
  }

  Future<void> _recuperar() async {
    final db = ref.read(supabaseProvider);
    final sesion = await db.sesionActiva();
    if (sesion == null) return;

    final actividad = await _buscarActividad(sesion.idActividad);
    if (actividad == null) return;

    state = SesionActivaEstado(
      sesion: sesion,
      actividad: actividad,
      transcurridos: sesion.transcurridos(),
    );
    _arrancarTimer();

    await CronometroNativo.instancia.iniciar(
      nombreActividad: actividad.nombre,
      colorHex: actividad.color,
      iniciadaMillis: sesion.iniciada.millisecondsSinceEpoch,
    );
  }

  Future<Actividad?> _buscarActividad(int id) async {
    final lista = await ref.read(actividadesProvider.future);
    for (final a in lista) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _arrancarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final sesion = state.sesion;
      if (sesion == null) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(transcurridos: sesion.transcurridos());
    });
  }
}
