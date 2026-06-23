/// Fila del dashboard que devuelve la RPC `obtener_resumen()`.
/// Ver PROYECTO.md sección 4.4.
class ResumenActividad {
  final int id;
  final String nombre;
  final String color;
  final int? objetivoDiario;
  final int acumuladoHoy;
  final int restanteHoy;
  final int excedenteHoy;
  final int acumuladoSemana;
  final int restanteSemanal;
  final bool sinDiasAsignados;
  final int promedioDiarioRestanteSemana;

  const ResumenActividad({
    required this.id,
    required this.nombre,
    required this.color,
    this.objetivoDiario,
    required this.acumuladoHoy,
    required this.restanteHoy,
    required this.excedenteHoy,
    required this.acumuladoSemana,
    required this.restanteSemanal,
    required this.sinDiasAsignados,
    required this.promedioDiarioRestanteSemana,
  });

  bool get tieneObjetivoDiario => objetivoDiario != null && objetivoDiario! > 0;

  /// Fracción 0..1 del objetivo diario completado hoy.
  /// Si no hay objetivo, devuelve 0 (el dashboard no muestra anillo).
  double get fraccionDiaria {
    if (!tieneObjetivoDiario) return 0;
    return (acumuladoHoy / objetivoDiario!).clamp(0.0, 1.0);
  }

  bool get objetivoCumplidoHoy => tieneObjetivoDiario && restanteHoy == 0;

  factory ResumenActividad.fromJson(Map<String, dynamic> json) {
    return ResumenActividad(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      color: json['color'] as String,
      objetivoDiario: json['objetivo_diario'] as int?,
      acumuladoHoy: (json['acumulado_hoy'] as num?)?.toInt() ?? 0,
      restanteHoy: (json['restante_hoy'] as num?)?.toInt() ?? 0,
      excedenteHoy: (json['excedente_hoy'] as num?)?.toInt() ?? 0,
      acumuladoSemana: (json['acumulado_semana'] as num?)?.toInt() ?? 0,
      restanteSemanal: (json['restante_semanal'] as num?)?.toInt() ?? 0,
      sinDiasAsignados: json['sin_dias_asignados'] as bool? ?? true,
      promedioDiarioRestanteSemana:
          (json['promedio_diario_restante_semana'] as num?)?.toInt() ?? 0,
    );
  }
}
