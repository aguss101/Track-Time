import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constantes/colores.dart';
import '../estado/sesion_activa.dart';
import '../util/formato.dart';

class BarraSesionActiva extends ConsumerWidget {
  final VoidCallback? alTocar;

  const BarraSesionActiva({super.key, this.alTocar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sesionActivaProvider);
    if (!estado.hayActiva) return const SizedBox.shrink();

    final color = ColoresActividad.desdeHex(estado.actividad!.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alTocar,
        child: Container(
          height: 34,
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  estado.actividad!.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                Formato.relojCompleto(estado.transcurridos),
                style: const TextStyle(
                  color: Colors.black87,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
