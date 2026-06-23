import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constantes/colores.dart';
import 'constantes/tema.dart';
import 'pantallas/splash/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colores.pantalla,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colores.pantalla,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: TrackTimeApp()));
}

class TrackTimeApp extends StatelessWidget {
  const TrackTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track-Time',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const SplashPage(),
    );
  }
}
