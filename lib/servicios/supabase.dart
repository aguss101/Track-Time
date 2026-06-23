import 'dart:convert';
import 'package:http/http.dart' as http;

import '../modelos/grupo.dart';
import '../modelos/actividad.dart';
import '../modelos/sesion.dart';
import '../modelos/resumen.dart';
import '../modelos/metrica.dart';

/// Cliente HTTP único hacia Supabase (REST + RPC, sin SDK).
///
/// Patrón de llamada definido en CLAUDE.md y PROYECTO.md sección 7.
/// Esta es la ÚNICA clase de la app que toca HTTP.
class Supabase {
  Supabase._();
  static final Supabase instancia = Supabase._();

  // ── Credenciales ────────────────────────────────────
  // TODO(Agustin): completar con la URL y anon key de tu proyecto Supabase.
  // App personal en el propio dispositivo — riesgo de exponer anon key aceptado
  // (ver PROYECTO.md sección 2). RLS + anon key limitan el acceso.
  static const String _url = 'https://TU_PROYECTO.supabase.co';
  static const String _anonKey = 'TU_ANON_KEY';

  static const Map<String, String> _headers = {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // ════════════════════════════════════════════════════
  // GRUPOS
  // ════════════════════════════════════════════════════

  Future<List<Grupo>> obtenerGrupos() async {
    final r = await http.get(
      Uri.parse('$_url/rest/v1/grupos?order=nombre.asc'),
      headers: _headers,
    );
    _verificar(r, 'obtenerGrupos');
    final lista = jsonDecode(r.body) as List;
    return lista.map((e) => Grupo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Grupo> crearGrupo(Grupo grupo) async {
    final r = await http.post(
      Uri.parse('$_url/rest/v1/grupos'),
      headers: _headers,
      body: jsonEncode(grupo.toJson()),
    );
    _verificar(r, 'crearGrupo');
    return Grupo.fromJson((jsonDecode(r.body) as List).first as Map<String, dynamic>);
  }

  Future<Grupo> actualizarGrupo(Grupo grupo) async {
    final r = await http.patch(
      Uri.parse('$_url/rest/v1/grupos?id=eq.${grupo.id}'),
      headers: _headers,
      body: jsonEncode(grupo.toJson()),
    );
    _verificar(r, 'actualizarGrupo');
    return Grupo.fromJson((jsonDecode(r.body) as List).first as Map<String, dynamic>);
  }

  Future<void> eliminarGrupo(int id) async {
    final r = await http.delete(
      Uri.parse('$_url/rest/v1/grupos?id=eq.$id'),
      headers: _headers,
    );
    _verificar(r, 'eliminarGrupo');
  }

  // ════════════════════════════════════════════════════
  // ACTIVIDADES
  // ════════════════════════════════════════════════════

  Future<List<Actividad>> obtenerActividades() async {
    final r = await http.get(
      Uri.parse('$_url/rest/v1/actividades?order=nombre.asc'),
      headers: _headers,
    );
    _verificar(r, 'obtenerActividades');
    final lista = jsonDecode(r.body) as List;
    return lista
        .map((e) => Actividad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Actividad> crearActividad(Actividad actividad) async {
    final r = await http.post(
      Uri.parse('$_url/rest/v1/actividades'),
      headers: _headers,
      body: jsonEncode(actividad.toJson()),
    );
    _verificar(r, 'crearActividad');
    return Actividad.fromJson(
        (jsonDecode(r.body) as List).first as Map<String, dynamic>);
  }

  Future<Actividad> actualizarActividad(Actividad actividad) async {
    final r = await http.patch(
      Uri.parse('$_url/rest/v1/actividades?id=eq.${actividad.id}'),
      headers: _headers,
      body: jsonEncode(actividad.toJson()),
    );
    _verificar(r, 'actualizarActividad');
    return Actividad.fromJson(
        (jsonDecode(r.body) as List).first as Map<String, dynamic>);
  }

  Future<void> eliminarActividad(int id) async {
    final r = await http.delete(
      Uri.parse('$_url/rest/v1/actividades?id=eq.$id'),
      headers: _headers,
    );
    _verificar(r, 'eliminarActividad');
  }

  // ════════════════════════════════════════════════════
  // SESIONES
  // ════════════════════════════════════════════════════

  /// Devuelve la sesión activa (finalizada IS NULL) o null si no hay ninguna.
  Future<Sesion?> sesionActiva() async {
    final r = await http.get(
      Uri.parse('$_url/rest/v1/sesiones?finalizada=is.null&limit=1'),
      headers: _headers,
    );
    _verificar(r, 'sesionActiva');
    final lista = jsonDecode(r.body) as List;
    if (lista.isEmpty) return null;
    return Sesion.fromJson(lista.first as Map<String, dynamic>);
  }

  /// Pausa/detiene una sesión: setea `finalizada`. El trigger calcula `duracion`.
  Future<Sesion> pausarSesion(int idSesion) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    final r = await http.patch(
      Uri.parse('$_url/rest/v1/sesiones?id=eq.$idSesion'),
      headers: _headers,
      body: jsonEncode({'finalizada': ahora}),
    );
    _verificar(r, 'pausarSesion');
    return Sesion.fromJson(
        (jsonDecode(r.body) as List).first as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════
  // SP — iniciar_sesion (atómico)
  // ════════════════════════════════════════════════════

  /// Cierra la sesión activa (si existe) y abre una nueva, en una transacción.
  /// Ver PROYECTO.md sección 4.5.
  Future<void> iniciarSesion(int idActividad) async {
    final r = await http.post(
      Uri.parse('$_url/rest/v1/rpc/iniciar_sesion'),
      headers: _headers,
      body: jsonEncode({'p_id_actividad': idActividad}),
    );
    _verificar(r, 'iniciarSesion');
  }

  // ════════════════════════════════════════════════════
  // RPC — métricas
  // ════════════════════════════════════════════════════

  Future<List<ResumenActividad>> obtenerResumen() async {
    final r = await http.post(
      Uri.parse('$_url/rest/v1/rpc/obtener_resumen'),
      headers: _headers,
      body: jsonEncode({}),
    );
    _verificar(r, 'obtenerResumen');
    final decoded = jsonDecode(r.body);
    if (decoded == null) return [];
    return (decoded as List)
        .map((e) => ResumenActividad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Metrica> obtenerMetricaDiaria(int idActividad) =>
      _metrica(Periodo.diario, 'obtener_metrica_diaria', idActividad);

  Future<Metrica> obtenerMetricaSemanal(int idActividad) =>
      _metrica(Periodo.semanal, 'obtener_metrica_semanal', idActividad);

  Future<Metrica> obtenerMetricaMensual(int idActividad) =>
      _metrica(Periodo.mensual, 'obtener_metrica_mensual', idActividad);

  Future<Metrica> obtenerMetricaAnual(int idActividad) =>
      _metrica(Periodo.anual, 'obtener_metrica_anual', idActividad);

  Future<Metrica> _metrica(Periodo p, String fn, int idActividad) async {
    final r = await http.post(
      Uri.parse('$_url/rest/v1/rpc/$fn'),
      headers: _headers,
      body: jsonEncode({'p_id_actividad': idActividad}),
    );
    _verificar(r, fn);
    return Metrica.fromJson(p, jsonDecode(r.body) as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════
  // Manejo de errores
  // ════════════════════════════════════════════════════

  void _verificar(http.Response r, String contexto) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw SupabaseException(contexto, r.statusCode, r.body);
    }
  }
}

class SupabaseException implements Exception {
  final String operacion;
  final int statusCode;
  final String cuerpo;

  SupabaseException(this.operacion, this.statusCode, this.cuerpo);

  @override
  String toString() => 'Error en $operacion ($statusCode): $cuerpo';
}
