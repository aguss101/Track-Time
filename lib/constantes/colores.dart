import 'package:flutter/material.dart';

class Colores {
  Colores._();

  static const Color pantalla = Color(0xFF1E1E21);
  static const Color card = Color(0xFF2E2E33);
  static const Color elevado = Color(0xFF55544F);

  static const Color textoPrimario = Color(0xFFEDECE8);
  static const Color textoSecundario = Color(0xFF9A9890);
  static const Color inactivo = Color(0xFF55544F);

  static const Color acento = Color(0xFF9DD929);

  static const Color borde = Color(0xFF3A3A3F);
}

class ColoresActividad {
  ColoresActividad._();

  static const Color rojo = Color(0xFFE05840);
  static const Color naranja = Color(0xFFE88A20);
  static const Color amarillo = Color(0xFFD4B030);
  static const Color verde = Color(0xFF4CB870);
  static const Color teal = Color(0xFF27B89A);
  static const Color azul = Color(0xFF4A90E8);
  static const Color violeta = Color(0xFF6D14CC);
  static const Color rosa = Color(0xFFB715D4);

  static const List<Color> todos = [
    rojo,
    naranja,
    amarillo,
    verde,
    teal,
    azul,
    violeta,
    rosa,
  ];

  static Color desdeHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colores.acento;
    var limpio = hex.replaceFirst('#', '').trim();
    if (limpio.length == 6) limpio = 'FF$limpio';
    final valor = int.tryParse(limpio, radix: 16);
    return valor == null ? Colores.acento : Color(valor);
  }

  /// Convierte un [Color] a hex `#RRGGBB` para guardar en la DB.
  static String aHex(Color color) {
    final argb = color.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${rgb.toUpperCase()}';
  }
}
