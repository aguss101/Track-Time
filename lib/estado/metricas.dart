import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/metrica.dart';
import 'proveedores.dart';

class MetricasActividad {
  final Metrica diaria;
  final Metrica semanal;
  final Metrica mensual;
  final Metrica anual;

  const MetricasActividad({
    required this.diaria,
    required this.semanal,
    required this.mensual,
    required this.anual,
  });
}

final metricasProvider =
    FutureProvider.family<MetricasActividad, int>((ref, idActividad) async {
  final db = ref.read(supabaseProvider);
  final resultados = await Future.wait([
    db.obtenerMetricaDiaria(idActividad),
    db.obtenerMetricaSemanal(idActividad),
    db.obtenerMetricaMensual(idActividad),
    db.obtenerMetricaAnual(idActividad),
  ]);
  return MetricasActividad(
    diaria: resultados[0],
    semanal: resultados[1],
    mensual: resultados[2],
    anual: resultados[3],
  );
});
