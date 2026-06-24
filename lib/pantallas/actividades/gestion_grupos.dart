import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../estado/proveedores.dart';
import '../../modelos/grupo.dart';

Future<void> mostrarGestionGrupos(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colores.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _GestionGrupos(),
  );
}

class _GestionGrupos extends ConsumerStatefulWidget {
  const _GestionGrupos();

  @override
  ConsumerState<_GestionGrupos> createState() => _GestionGruposState();
}

class _GestionGruposState extends ConsumerState<_GestionGrupos> {
  final _nuevo = TextEditingController();
  bool _agregando = false;

  @override
  void dispose() {
    _nuevo.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nuevo.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _agregando = true);
    try {
      await ref
          .read(gruposProvider.notifier)
          .crear(Grupo(id: 0, nombre: nombre));
      _nuevo.clear();
    } catch (e) {
      _error('No se pudo crear: $e');
    } finally {
      if (mounted) setState(() => _agregando = false);
    }
  }

  Future<void> _renombrar(Grupo g) async {
    final ctrl = TextEditingController(text: g.nombre);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renombrar grupo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colores.textoPrimario),
          decoration: const InputDecoration(hintText: 'Nombre del grupo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo != null && nuevo.isNotEmpty && nuevo != g.nombre) {
      try {
        await ref
            .read(gruposProvider.notifier)
            .actualizar(g.copyWith(nombre: nuevo));
      } catch (e) {
        _error('No se pudo renombrar: $e');
      }
    }
  }

  Future<void> _eliminar(Grupo g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          'Las actividades de "${g.nombre}" no se borran, quedan sin grupo.',
          style: const TextStyle(color: Colores.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: ColoresActividad.rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(gruposProvider.notifier).eliminar(g.id);
      } catch (e) {
        _error('No se pudo eliminar: $e');
      }
    }
  }

  void _error(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(gruposProvider);
    final tecladoInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + tecladoInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colores.inactivo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Grupos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colores.textoPrimario,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nuevo,
                  style: const TextStyle(color: Colores.textoPrimario),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nuevo grupo',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _crear(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _agregando ? null : _crear,
                icon: const Icon(Icons.add_circle, color: Colores.acento),
              ),
            ],
          ),
          const SizedBox(height: 8),
          grupos.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Colores.acento),
              ),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: Colores.textoSecundario),
            ),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Todavía no hay grupos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colores.textoSecundario),
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final g = lista[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        g.nombre,
                        style: const TextStyle(color: Colores.textoPrimario),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colores.textoSecundario,
                            ),
                            onPressed: () => _renombrar(g),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colores.textoSecundario,
                            ),
                            onPressed: () => _eliminar(g),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
