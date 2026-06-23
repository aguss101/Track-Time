import 'package:flutter/material.dart';

/// Paleta de la app — modo oscuro único.
/// Ver PROYECTO.md sección 11 y CLAUDE.md.
class Colores {
  Colores._();

  // ── Fondos ──────────────────────────────────────────
  static const Color pantalla = Color(0xFF1E1E21); // fondo de todas las pantallas
  static const Color card = Color(0xFF2E2E33); // cards y surfaces
  static const Color elevado = Color(0xFF55544F); // modals, chips activos

  // ── Texto ───────────────────────────────────────────
  static const Color textoPrimario = Color(0xFFEDECE8);
  static const Color textoSecundario = Color(0xFF9A9890);
  static const Color inactivo = Color(0xFF55544F);

  // ── Acento ──────────────────────────────────────────
  static const Color acento = Color(0xFF9DD929); // verde lima

  // ── Borde sutil sobre cards ─────────────────────────
  static const Color borde = Color(0xFF3A3A3F);
}

/// Set fijo de 8 colores que el usuario elige al crear una actividad.
/// El orden y los hex son fijos — ver PROYECTO.md sección 11.2.
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

  /// Lista ordenada para mostrar en el selector de color.
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

  /// Convierte un hex de la DB (`#RRGGBB`) a [Color].
  /// Si el valor es nulo o inválido, devuelve [Colores.acento].
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
