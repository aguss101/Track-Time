import 'package:flutter/material.dart';

import '../constantes/colores.dart';

/// Grilla de los 8 colores fijos para elegir el color de una actividad.
class SelectorColor extends StatelessWidget {
  final String seleccionadoHex;
  final ValueChanged<String> alElegir;

  const SelectorColor({
    super.key,
    required this.seleccionadoHex,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final seleccionado = ColoresActividad.desdeHex(seleccionadoHex);
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: ColoresActividad.todos.map((color) {
        final activo = color.toARGB32() == seleccionado.toARGB32();
        return GestureDetector(
          onTap: () => alElegir(ColoresActividad.aHex(color)),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: activo
                  ? Border.all(color: Colores.textoPrimario, width: 3)
                  : null,
            ),
            child: activo
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
