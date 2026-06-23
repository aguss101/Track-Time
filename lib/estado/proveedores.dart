import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servicios/supabase.dart';
import '../modelos/grupo.dart';
import '../modelos/actividad.dart';
import '../modelos/resumen.dart';

/// Acceso al cliente HTTP único.
final supabaseProvider = Provider<Supabase>((ref) => Supabase.instancia);

// ════════════════════════════════════════════════════
// GRUPOS
// ════════════════════════════════════════════════════

final gruposProvider =
    AsyncNotifierProvider<GruposNotifier, List<Grupo>>(GruposNotifier.new);

class GruposNotifier extends AsyncNotifier<List<Grupo>> {
  Supabase get _db => ref.read(supabaseProvider);

  @override
  Future<List<Grupo>> build() => _db.obtenerGrupos();

  Future<void> crear(Grupo grupo) async {
    await _db.crearGrupo(grupo);
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizar(Grupo grupo) async {
    await _db.actualizarGrupo(grupo);
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminar(int id) async {
    await _db.eliminarGrupo(id);
    ref.invalidateSelf();
    await future;
    // Las actividades pueden haber quedado sin grupo (ON DELETE SET NULL).
    ref.invalidate(actividadesProvider);
  }
}

// ════════════════════════════════════════════════════
// ACTIVIDADES
// ════════════════════════════════════════════════════

final actividadesProvider =
    AsyncNotifierProvider<ActividadesNotifier, List<Actividad>>(
        ActividadesNotifier.new);

class ActividadesNotifier extends AsyncNotifier<List<Actividad>> {
  Supabase get _db => ref.read(supabaseProvider);

  @override
  Future<List<Actividad>> build() => _db.obtenerActividades();

  Future<void> crear(Actividad actividad) async {
    await _db.crearActividad(actividad);
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizar(Actividad actividad) async {
    await _db.actualizarActividad(actividad);
    ref.invalidateSelf();
    await future;
    ref.invalidate(resumenProvider);
  }

  Future<void> eliminar(int id) async {
    await _db.eliminarActividad(id);
    ref.invalidateSelf();
    await future;
    ref.invalidate(resumenProvider);
  }
}

// ════════════════════════════════════════════════════
// RESUMEN (dashboard de Inicio)
// ════════════════════════════════════════════════════

final resumenProvider =
    AsyncNotifierProvider<ResumenNotifier, List<ResumenActividad>>(
        ResumenNotifier.new);

class ResumenNotifier extends AsyncNotifier<List<ResumenActividad>> {
  @override
  Future<List<ResumenActividad>> build() =>
      ref.read(supabaseProvider).obtenerResumen();

  Future<void> refrescar() async {
    ref.invalidateSelf();
    await future;
  }
}
