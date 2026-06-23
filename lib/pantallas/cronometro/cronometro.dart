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

  Future<void> _iniciar(Actividad actividad) async {
    try {
      await ref.read(sesionActivaProvider.notifier).iniciar(actividad);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo iniciar: $e')));
      }
    }
  }

  Future<void> _pausar() async {
    try {
      await ref.read(sesionActivaProvider.notifier).pausar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo pausar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sesionActivaProvider);
    final actividades = ref.watch(actividadesProvider);

    final actividad = estado.hayActiva ? estado.actividad : _seleccionada;
    final corriendo = estado.hayActiva;

    return actividades.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colores.acento)),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: Colores.textoSecundario),
        ),
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
              alElegir: (a) {
                if (corriendo && estado.actividad?.id != a.id) {
                  _pausar();
                }
                setState(() => _seleccionada = a);
              },
            ),
            Expanded(
              child: actividad == null
                  ? const _SinSeleccion()
                  : _Reloj(
                      actividad: actividad,
                      estado: estado,
                      alTocar: () =>
                          corriendo ? _pausar() : _iniciar(actividad),
                    ),
            ),
            _BotonCircular(
              corriendo: corriendo,
              alTocar: actividad == null
                  ? null
                  : () => corriendo ? _pausar() : _iniciar(actividad),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

class _SelectorActividades extends StatelessWidget {
  final List<Actividad> actividades;
  final int? seleccionadaId;
  final ValueChanged<Actividad> alElegir;

  const _SelectorActividades({
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
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
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
  final VoidCallback alTocar;

  const _Reloj({
    required this.actividad,
    required this.estado,
    required this.alTocar,
  });

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

        return _anillo(
          color,
          transcurridos,
          restanteVivo,
          promedio,
          progreso: progreso,
          sinObjetivo: obj <= 0,
        );
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
          GestureDetector(
            onTap: alTocar,
            child: AnilloProgreso(
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
          ),
          const SizedBox(height: 32),
          if (!sinObjetivo)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(
                  etiqueta: 'Faltan hoy',
                  valor: restante == null ? '—' : Formato.compacto(restante),
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

class _BotonCircular extends StatelessWidget {
  final bool corriendo;
  final VoidCallback? alTocar;

  const _BotonCircular({required this.corriendo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final habilitado = alTocar != null;
    final fondo = !habilitado
        ? Colores.elevado
        : (corriendo ? Colores.elevado : Colores.acento);
    final iconoColor = !habilitado
        ? Colores.inactivo
        : (corriendo ? Colores.textoPrimario : Colors.black);

    return Material(
      color: fondo,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: habilitado ? 3 : 0,
      child: InkWell(
        onTap: alTocar,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Icon(
            corriendo ? Icons.pause : Icons.play_arrow,
            color: iconoColor,
            size: 38,
          ),
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
