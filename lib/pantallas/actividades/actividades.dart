import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constantes/colores.dart';
import '../../estado/proveedores.dart';
import '../../modelos/actividad.dart';
import '../../modelos/grupo.dart';
import '../../util/formato.dart';
import 'formulario_actividad.dart';
import 'gestion_grupos.dart';

class ActividadesPage extends ConsumerWidget {
  const ActividadesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actividades = ref.watch(actividadesProvider);
    final grupos = ref.watch(gruposProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              const Text(
                'Actividades',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colores.textoPrimario,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.folder_outlined),
                color: Colores.textoSecundario,
                tooltip: 'Grupos',
                onPressed: () => mostrarGestionGrupos(context),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colores.acento),
                tooltip: 'Nueva actividad',
                onPressed: () => _abrirFormulario(context, null),
              ),
            ],
          ),
        ),
        Expanded(
          child: actividades.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colores.acento),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar las actividades.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colores.textoSecundario),
                ),
              ),
            ),
            data: (lista) {
              if (lista.isEmpty) return const _Vacio();
              final mapaGrupos = {
                for (final g in grupos.value ?? <Grupo>[]) g.id: g,
              };
              return _ListaAgrupada(
                actividades: lista,
                grupos: mapaGrupos,
                alEditar: (a) => _abrirFormulario(context, a),
                alEliminar: (a) => _confirmarEliminar(context, ref, a),
              );
            },
          ),
        ),
      ],
    );
  }

  void _abrirFormulario(BuildContext context, Actividad? actividad) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioActividad(actividad: actividad),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Actividad a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text(
          '¿Eliminar "${a.nombre}"? Se borrarán también todas sus sesiones.',
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
        await ref.read(actividadesProvider.notifier).eliminar(a.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
        }
      }
    }
  }
}

class _ListaAgrupada extends StatelessWidget {
  final List<Actividad> actividades;
  final Map<int, Grupo> grupos;
  final ValueChanged<Actividad> alEditar;
  final ValueChanged<Actividad> alEliminar;

  const _ListaAgrupada({
    required this.actividades,
    required this.grupos,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final porGrupo = <int?, List<Actividad>>{};
    for (final a in actividades) {
      porGrupo.putIfAbsent(a.idGrupo, () => []).add(a);
    }

    final claves = porGrupo.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return (grupos[a]?.nombre ?? '').compareTo(grupos[b]?.nombre ?? '');
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        for (final clave in claves) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              clave == null ? 'Sin grupo' : (grupos[clave]?.nombre ?? 'Grupo'),
              style: const TextStyle(
                color: Colores.textoSecundario,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...porGrupo[clave]!.map(
            (a) => _FilaActividad(
              actividad: a,
              alEditar: () => alEditar(a),
              alEliminar: () => alEliminar(a),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilaActividad extends StatelessWidget {
  final Actividad actividad;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const _FilaActividad({
    required this.actividad,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColoresActividad.desdeHex(actividad.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colores.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          title: Text(
            actividad.nombre,
            style: const TextStyle(
              color: Colores.textoPrimario,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _resumenObjetivos(actividad),
            style: const TextStyle(
              color: Colores.textoSecundario,
              fontSize: 13,
            ),
          ),
          trailing: PopupMenuButton<String>(
            color: Colores.elevado,
            icon: const Icon(Icons.more_vert, color: Colores.textoSecundario),
            onSelected: (v) => v == 'editar' ? alEditar() : alEliminar(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
          onTap: alEditar,
        ),
      ),
    );
  }

  String _resumenObjetivos(Actividad a) {
    final partes = <String>[];
    if (a.objetivoDiario != null) {
      partes.add('${Formato.compacto(a.objetivoDiario!)}/día');
    }
    if (a.objetivoSemanal != null) {
      partes.add('${Formato.compacto(a.objetivoSemanal!)}/sem');
    }
    if (partes.isEmpty) return 'Sin objetivo';
    return partes.join('  ·  ');
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task, size: 48, color: Colores.inactivo),
            SizedBox(height: 12),
            Text(
              'No hay actividades todavía.\nTocá + para crear la primera.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colores.textoSecundario, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
