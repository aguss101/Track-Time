import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constantes/colores.dart';
import '../componentes/barra_sesion_activa.dart';
import 'inicio/inicio.dart';
import 'cronometro/cronometro.dart';
import 'actividades/actividades.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int _indice = 0;

  void _ir(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BarraSesionActiva(alTocar: () => _ir(1)),
            Expanded(
              child: IndexedStack(
                index: _indice,
                children: const [
                  InicioPage(),
                  CronometroPage(),
                  ActividadesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _BotonCronometro(
        activo: _indice == 1,
        alTocar: () => _ir(1),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BarraNav(indice: _indice, alElegir: _ir),
    );
  }
}

class _BotonCronometro extends StatelessWidget {
  final bool activo;
  final VoidCallback alTocar;

  const _BotonCronometro({required this.activo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: FloatingActionButton(
        onPressed: alTocar,
        backgroundColor: activo ? Colores.acento : Colores.elevado,
        foregroundColor: activo ? Colors.black : Colores.textoPrimario,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.timer_outlined, size: 28),
      ),
    );
  }
}

class _BarraNav extends StatelessWidget {
  final int indice;
  final ValueChanged<int> alElegir;

  const _BarraNav({required this.indice, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colores.card,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 64,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ItemNav(
            icono: Icons.home_outlined,
            iconoActivo: Icons.home,
            etiqueta: 'Inicio',
            activo: indice == 0,
            alTocar: () => alElegir(0),
          ),
          const SizedBox(width: 60),
          _ItemNav(
            icono: Icons.list_alt_outlined,
            iconoActivo: Icons.list_alt,
            etiqueta: 'Actividades',
            activo: indice == 2,
            alTocar: () => alElegir(2),
          ),
        ],
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final bool activo;
  final VoidCallback alTocar;

  const _ItemNav({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    required this.activo,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colores.acento : Colores.textoSecundario;
    return Expanded(
      child: InkWell(
        onTap: alTocar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(activo ? iconoActivo : icono, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
