import 'package:flutter/material.dart';

import 'colores.dart';

ThemeData construirTema() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: Colores.pantalla,
    colorScheme: const ColorScheme.dark(
      surface: Colores.pantalla,
      primary: Colores.acento,
      secondary: Colores.acento,
      onPrimary: Colors.black,
      onSurface: Colores.textoPrimario,
    ),
    canvasColor: Colores.pantalla,
    cardColor: Colores.card,
    dividerColor: Colores.borde,
    textTheme: base.textTheme.apply(
      bodyColor: Colores.textoPrimario,
      displayColor: Colores.textoPrimario,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.pantalla,
      elevation: 0,
      foregroundColor: Colores.textoPrimario,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colores.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    iconTheme: const IconThemeData(color: Colores.textoPrimario),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colores.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colores.acento, width: 2),
      ),
      hintStyle: const TextStyle(color: Colores.textoSecundario),
      labelStyle: const TextStyle(color: Colores.textoSecundario),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colores.acento,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colores.acento),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colores.acento,
      foregroundColor: Colors.black,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colores.elevado,
      contentTextStyle: TextStyle(color: Colores.textoPrimario),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colores.card),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colores.card),
  );
}
