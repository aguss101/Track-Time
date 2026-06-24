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

final metricasGlobalProvider = FutureProvider<MetricasActividad>((ref) async {
  final actividades = await ref.watch(actividadesProvider.future);
  if (actividades.isEmpty) {
    Metrica vacia(Periodo p) =>
        Metrica(periodo: p, acumulado: 0, restante: 0, excedente: 0);
    return MetricasActividad(
      diaria: vacia(Periodo.diario),
      semanal: vacia(Periodo.semanal),
      mensual: vacia(Periodo.mensual),
      anual: vacia(Periodo.anual),
    );
  }

  final todas = await Future.wait(
    actividades.map((a) => ref.watch(metricasProvider(a.id).future)),
  );

  Metrica sumar(Periodo p, Metrica Function(MetricasActividad) seleccionar) {
    var acumulado = 0;
    var restante = 0;
    var excedente = 0;
    for (final m in todas) {
      final metrica = seleccionar(m);
      acumulado += metrica.acumulado;
      restante += metrica.restante;
      excedente += metrica.excedente;
    }
    return Metrica(
      periodo: p,
      acumulado: acumulado,
      restante: restante,
      excedente: excedente,
    );
  }

  return MetricasActividad(
    diaria: sumar(Periodo.diario, (m) => m.diaria),
    semanal: sumar(Periodo.semanal, (m) => m.semanal),
    mensual: sumar(Periodo.mensual, (m) => m.mensual),
    anual: sumar(Periodo.anual, (m) => m.anual),
  );
});

final metricasProvider = FutureProvider.family<MetricasActividad, int>((
  ref,
  idActividad,
) async {
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
