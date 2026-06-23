import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constantes/colores.dart';
import '../shell.dart';

/// Pantalla de bienvenida con el logo. Se muestra brevemente al abrir la app
/// (sobre el splash nativo de color sólido) y luego entra al Shell.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _entrar();
  }

  Future<void> _entrar() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => const Shell(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.pantalla,
      body: Center(
        child: SvgPicture.asset(
          'assets/imagenes/logo.svg',
          width: 140,
          colorFilter: const ColorFilter.mode(
            Colores.textoPrimario,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
