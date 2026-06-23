import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../componentes/anillo_progreso.dart';
import '../../estado/proveedores.dart';
import '../../modelos/resumen.dart';
import '../../util/formato.dart';
import '../metricas/metricas.dart';

/// Dashboard. Resumen diario de todas las actividades (RPC `obtener_resumen`).
/// Botón de métricas arriba a la izquierda (no va en el nav).
class InicioPage extends ConsumerWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(),
        Expanded(
          child: resumen.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colores.acento),
            ),
            error: (e, _) => _Error(
              mensaje: '$e',
              alReintentar: () => ref.invalidate(resumenProvider),
            ),
            data: (lista) {
              if (lista.isEmpty) return const _Vacio();
              return RefreshIndicator(
                color: Colores.acento,
                backgroundColor: Colores.card,
                onRefresh: () =>
                    ref.read(resumenProvider.notifier).refrescar(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CardActividad(r: lista[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            color: Colores.textoPrimario,
            tooltip: 'Métricas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MetricasPage()),
            ),
          ),
          const Spacer(),
          const Text(
            'Hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colores.textoPrimario,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CardActividad extends StatelessWidget {
  final ResumenActividad r;
  const _CardActividad({required this.r});

  @override
  Widget build(BuildContext context) {
    final color = ColoresActividad.desdeHex(r.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnilloProgreso(
            progreso: r.fraccionDiaria,
            color: color,
            tamano: 64,
            grosor: 6,
            sinObjetivo: !r.tieneObjetivoDiario,
            child: r.objetivoCumplidoHoy
                ? Icon(Icons.check, color: color, size: 22)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colores.textoPrimario,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _detalle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalle() {
    if (!r.tieneObjetivoDiario) {
      // Sin objetivo: solo tiempo acumulado.
      return Text(
        Formato.compacto(r.acumuladoHoy),
        style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
      );
    }

    if (r.objetivoCumplidoHoy) {
      final extra = r.excedenteHoy > 0
          ? '  ·  +${Formato.compacto(r.excedenteHoy)} extra'
          : '';
      return Text(
        'Objetivo cumplido$extra',
        style: const TextStyle(fontSize: 14, color: Colores.acento),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
        children: [
          TextSpan(
            text: Formato.compacto(r.acumuladoHoy),
            style: const TextStyle(
              color: Colores.textoPrimario,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' de ${Formato.compacto(r.objetivoDiario!)}'),
          TextSpan(text: '  ·  faltan ${Formato.compacto(r.restanteHoy)}'),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colores.inactivo),
            SizedBox(height: 12),
            Text(
              'Todavía no hay actividades.\nCreá una desde la pestaña Actividades.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.textoSecundario, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;
  const _Error({required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colores.inactivo),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el resumen',
              style: TextStyle(color: Colores.textoPrimario, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: Colores.textoSecundario, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
