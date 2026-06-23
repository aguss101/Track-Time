import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../estado/proveedores.dart';
import '../../estado/metricas.dart';
import '../../modelos/actividad.dart';
import '../../modelos/metrica.dart';
import '../../util/formato.dart';

class MetricasPage extends ConsumerStatefulWidget {
  const MetricasPage({super.key});

  @override
  ConsumerState<MetricasPage> createState() => _MetricasPageState();
}

class _MetricasPageState extends ConsumerState<MetricasPage> {
  int? _actividadId;
  Periodo _periodo = Periodo.diario;

  @override
  Widget build(BuildContext context) {
    final actividades = ref.watch(actividadesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: actividades.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colores.acento),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colores.textoSecundario)),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Creá actividades para ver métricas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colores.textoSecundario, fontSize: 15),
                ),
              ),
            );
          }

          final seleccionada = _actividadId ?? lista.first.id;
          final actividad = lista.firstWhere((a) => a.id == seleccionada,
              orElse: () => lista.first);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelectorActividad(
                actividades: lista,
                seleccionadaId: seleccionada,
                alElegir: (id) => setState(() => _actividadId = id),
              ),
              _SelectorPeriodo(
                periodo: _periodo,
                alElegir: (p) => setState(() => _periodo = p),
              ),
              Expanded(
                child: _Contenido(actividad: actividad, periodo: _periodo),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectorActividad extends StatelessWidget {
  final List<Actividad> actividades;
  final int seleccionadaId;
  final ValueChanged<int> alElegir;

  const _SelectorActividad({
    required this.actividades,
    required this.seleccionadaId,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: actividades.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final a = actividades[i];
          final color = ColoresActividad.desdeHex(a.color);
          final activo = a.id == seleccionadaId;
          return GestureDetector(
            onTap: () => alElegir(a.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: activo ? Colores.elevado : Colores.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: activo ? color : Colores.borde,
                    width: activo ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    a.nombre,
                    style: TextStyle(
                      color: activo
                          ? Colores.textoPrimario
                          : Colores.textoSecundario,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  final Periodo periodo;
  final ValueChanged<Periodo> alElegir;

  const _SelectorPeriodo({required this.periodo, required this.alElegir});

  static const _etiquetas = {
    Periodo.diario: 'Diario',
    Periodo.semanal: 'Semanal',
    Periodo.mensual: 'Mensual',
    Periodo.anual: 'Anual',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colores.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: Periodo.values.map((p) {
          final activo = p == periodo;
          return Expanded(
            child: GestureDetector(
              onTap: () => alElegir(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activo ? Colores.acento : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _etiquetas[p]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: activo ? Colors.black : Colores.textoSecundario,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  final Actividad actividad;
  final Periodo periodo;

  const _Contenido({required this.actividad, required this.periodo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = ref.watch(metricasProvider(actividad.id));

    return metricas.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colores.acento),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar la métrica.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.textoSecundario)),
        ),
      ),
      data: (m) {
        final metrica = switch (periodo) {
          Periodo.diario => m.diaria,
          Periodo.semanal => m.semanal,
          Periodo.mensual => m.mensual,
          Periodo.anual => m.anual,
        };
        return RefreshIndicator(
          color: Colores.acento,
          backgroundColor: Colores.card,
          onRefresh: () async => ref.invalidate(metricasProvider(actividad.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: _tarjetas(metrica),
          ),
        );
      },
    );
  }

  List<Widget> _tarjetas(Metrica m) {
    final color = ColoresActividad.desdeHex(actividad.color);
    final widgets = <Widget>[
      Row(
        children: [
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Acumulado',
              valor: Formato.compacto(m.acumulado),
              color: color,
              resaltado: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Restante',
              valor: Formato.compacto(m.restante),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
    ];

    if (m.excedente > 0) {
      widgets.add(_Tarjeta(
        etiqueta: 'Excedente',
        valor: '+${Formato.compacto(m.excedente)}',
        color: Colores.acento,
      ));
      widgets.add(const SizedBox(height: 12));
    }

    // Extras por período.
    if (periodo == Periodo.semanal) {
      if (m.sinDiasAsignados == true) {
        widgets.add(const _Aviso(
          texto:
              'Esta actividad no tiene días asignados. El promedio semanal se '
              'reparte entre hoy y el domingo hasta que asignes días.',
        ));
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(Row(
        children: [
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Días restantes',
              valor: '${m.diasRestantes ?? 0}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Promedio/día',
              valor: Formato.compacto(m.promedioDiarioRestante ?? 0),
            ),
          ),
        ],
      ));
    } else if (periodo == Periodo.mensual) {
      widgets.add(Row(
        children: [
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Semanas restantes',
              valor: '${m.semanasRestantes ?? 0}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tarjeta(
              etiqueta: 'Promedio/semana',
              valor: Formato.compacto(m.promedioSemanalRestante ?? 0),
            ),
          ),
        ],
      ));
    }

    return widgets;
  }
}

class _Tarjeta extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;
  final bool resaltado;

  const _Tarjeta({
    required this.etiqueta,
    required this.valor,
    this.color,
    this.resaltado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.card,
        borderRadius: BorderRadius.circular(14),
        border: resaltado && color != null
            ? Border.all(color: color!.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(color: Colores.textoSecundario, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: color ?? Colores.textoPrimario,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresActividad.amarillo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: ColoresActividad.amarillo.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: ColoresActividad.amarillo, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                  color: Colores.textoPrimario, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
