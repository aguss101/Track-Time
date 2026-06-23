import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../constantes/colores.dart';

/// - [progreso].
/// - [child]
class AnilloProgreso extends StatelessWidget {
  final double progreso;
  final Color color;
  final double tamano;
  final double grosor;
  final Widget? child;

  final bool sinObjetivo;

  const AnilloProgreso({
    super.key,
    required this.progreso,
    required this.color,
    this.tamano = 64,
    this.grosor = 6,
    this.child,
    this.sinObjetivo = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(
        painter: _AnilloPainter(
          progreso: progreso.clamp(0.0, 1.0),
          color: color,
          grosor: grosor,
          sinObjetivo: sinObjetivo,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  final double progreso;
  final Color color;
  final double grosor;
  final bool sinObjetivo;

  _AnilloPainter({
    required this.progreso,
    required this.color,
    required this.grosor,
    required this.sinObjetivo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (math.min(size.width, size.height) - grosor) / 2;

    final fondo = Paint()
      ..color = Colores.elevado.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centro, radio, fondo);

    if (sinObjetivo || progreso <= 0) return;

    final arco = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    const inicio = -math.pi / 2;
    final barrido = 2 * math.pi * progreso;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      inicio,
      barrido,
      false,
      arco,
    );
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.progreso != progreso ||
      old.color != color ||
      old.grosor != grosor ||
      old.sinObjetivo != sinObjetivo;
}
