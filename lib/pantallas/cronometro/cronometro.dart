import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../componentes/anillo_progreso.dart';
import '../../estado/proveedores.dart';
import '../../estado/sesion_activa.dart';
import '../../estado/metricas.dart';
import '../../modelos/actividad.dart';
import '../../util/formato.dart';

class CronometroPage extends ConsumerStatefulWidget {
  const CronometroPage({super.key});

  @override
  ConsumerState<CronometroPage> createState() => _CronometroPageState();
}

class _CronometroPageState extends ConsumerState<CronometroPage> {
  Actividad? _seleccionada;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sesionActivaProvider);
    final actividades = ref.watch(actividadesProvider);

    final actividad = estado.hayActiva ? estado.actividad : _seleccionada;

    return actividades.when(
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
                'Creá una actividad para empezar a cronometrar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colores.textoSecundario, fontSize: 15),
              ),
            ),
          );
        }

        return Column(
          children: [
            _SelectorActividades(
              actividades: lista,
              seleccionadaId: actividad?.id,
              corriendo: estado.hayActiva,
              alElegir: (a) {
                if (estado.hayActiva) {
                  ref.read(sesionActivaProvider.notifier).iniciar(a);
                }
                setState(() => _seleccionada = a);
              },
            ),
            Expanded(
              child: actividad == null
                  ? const _SinSeleccion()
                  : _Reloj(actividad: actividad, estado: estado),
            ),
            _Controles(
              actividad: actividad,
              estado: estado,
              alPlay: actividad == null
                  ? null
                  : () =>
                      ref.read(sesionActivaProvider.notifier).iniciar(actividad),
              alPausar: () =>
                  ref.read(sesionActivaProvider.notifier).pausar(),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _SelectorActividades extends StatelessWidget {
  final List<Actividad> actividades;
  final int? seleccionadaId;
  final bool corriendo;
  final ValueChanged<Actividad> alElegir;

  const _SelectorActividades({
    required this.actividades,
    required this.seleccionadaId,
    required this.corriendo,
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
            onTap: () => alElegir(a),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: activo ? Colores.elevado : Colores.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activo ? color : Colores.borde,
                  width: activo ? 2 : 1,
                ),
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

class _Reloj extends ConsumerWidget {
  final Actividad actividad;
  final SesionActivaEstado estado;

  const _Reloj({required this.actividad, required this.estado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ColoresActividad.desdeHex(actividad.color);
    final corriendoEsta =
        estado.hayActiva && estado.actividad?.id == actividad.id;
    final transcurridos = corriendoEsta ? estado.transcurridos : 0;

    final metricas = ref.watch(metricasProvider(actividad.id));

    return metricas.when(
      loading: () => _anillo(color, transcurridos, null, null),
      error: (_, _) => _anillo(color, transcurridos, null, null),
      data: (m) {
        final obj = actividad.objetivoDiario ?? 0;
        final acumuladoVivo = m.diaria.acumulado + transcurridos;
        final restanteVivo = obj > 0 ? (obj - acumuladoVivo).clamp(0, obj) : 0;
        final progreso = obj > 0 ? acumuladoVivo / obj : 0.0;
        final promedio = m.semanal.promedioDiarioRestante ?? 0;

        return _anillo(color, transcurridos, restanteVivo, promedio,
            progreso: progreso, sinObjetivo: obj <= 0);
      },
    );
  }

  Widget _anillo(
    Color color,
    int transcurridos,
    int? restante,
    int? promedio, {
    double progreso = 0,
    bool sinObjetivo = true,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnilloProgreso(
            progreso: progreso,
            color: color,
            tamano: 260,
            grosor: 12,
            sinObjetivo: sinObjetivo,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formato.relojCompleto(transcurridos),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: Colores.textoPrimario,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actividad.nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (!sinObjetivo)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(
                  etiqueta: 'Faltan hoy',
                  valor: restante == null
                      ? '—'
                      : Formato.compacto(restante),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colores.borde,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                _Stat(
                  etiqueta: 'Promedio/día',
                  valor: promedio == null || promedio == 0
                      ? '—'
                      : Formato.compacto(promedio),
                ),
              ],
            )
          else
            const Text(
              'Sin objetivo diario',
              style: TextStyle(color: Colores.textoSecundario, fontSize: 14),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Stat({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colores.textoPrimario,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 12, color: Colores.textoSecundario),
        ),
      ],
    );
  }
}

class _Controles extends StatelessWidget {
  final Actividad? actividad;
  final SesionActivaEstado estado;
  final VoidCallback? alPlay;
  final VoidCallback alPausar;

  const _Controles({
    required this.actividad,
    required this.estado,
    required this.alPlay,
    required this.alPausar,
  });

  @override
  Widget build(BuildContext context) {
    final corriendo = estado.hayActiva;

    if (corriendo) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: alPausar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.elevado,
              foregroundColor: Colores.textoPrimario,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.pause),
            label: const Text('Pausar'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: alPlay,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.play_arrow),
          label: Text(actividad == null ? 'Elegí una actividad' : 'Iniciar'),
        ),
      ),
    );
  }
}

class _SinSeleccion extends StatelessWidget {
  const _SinSeleccion();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 44, color: Colores.inactivo),
            SizedBox(height: 12),
            Text(
              'Elegí una actividad arriba para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.textoSecundario, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
