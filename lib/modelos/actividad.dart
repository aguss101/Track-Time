class Actividad {
  final int id;
  final int? idGrupo;
  final String nombre;
  final String color;
  final List<int> dias;
  final int? cantidadDiasSemana;
  final DateTime? fechaFin;
  final int? objetivoDiario;
  final int? objetivoSemanal;
  final int? objetivoMensual;
  final int? objetivoAnual;
  final DateTime? creado;

  const Actividad({
    required this.id,
    this.idGrupo,
    required this.nombre,
    required this.color,
    this.dias = const [],
    this.cantidadDiasSemana,
    this.fechaFin,
    this.objetivoDiario,
    this.objetivoSemanal,
    this.objetivoMensual,
    this.objetivoAnual,
    this.creado,
  });

  bool get tieneObjetivoDiario => objetivoDiario != null && objetivoDiario! > 0;

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] as int,
      idGrupo: json['id_grupo'] as int?,
      nombre: json['nombre'] as String,
      color: json['color'] as String,
      dias: _listaInt(json['dias']),
      cantidadDiasSemana: json['cantidad_dias_semana'] as int?,
      fechaFin: json['fecha_fin'] == null
          ? null
          : DateTime.parse(json['fecha_fin'] as String),
      objetivoDiario: json['objetivo_diario'] as int?,
      objetivoSemanal: json['objetivo_semanal'] as int?,
      objetivoMensual: json['objetivo_mensual'] as int?,
      objetivoAnual: json['objetivo_anual'] as int?,
      creado: json['creado'] == null
          ? null
          : DateTime.parse(json['creado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_grupo': idGrupo,
      'nombre': nombre,
      'color': color,
      'dias': dias,
      'cantidad_dias_semana': cantidadDiasSemana,
      'fecha_fin': _fechaAIso(fechaFin),
      'objetivo_diario': objetivoDiario,
      'objetivo_semanal': objetivoSemanal,
      'objetivo_mensual': objetivoMensual,
      'objetivo_anual': objetivoAnual,
    };
  }

  Actividad copyWith({
    int? idGrupo,
    bool limpiarGrupo = false,
    String? nombre,
    String? color,
    List<int>? dias,
    int? cantidadDiasSemana,
    DateTime? fechaFin,
    int? objetivoDiario,
    int? objetivoSemanal,
    int? objetivoMensual,
    int? objetivoAnual,
  }) {
    return Actividad(
      id: id,
      idGrupo: limpiarGrupo ? null : (idGrupo ?? this.idGrupo),
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      dias: dias ?? this.dias,
      cantidadDiasSemana: cantidadDiasSemana ?? this.cantidadDiasSemana,
      fechaFin: fechaFin ?? this.fechaFin,
      objetivoDiario: objetivoDiario ?? this.objetivoDiario,
      objetivoSemanal: objetivoSemanal ?? this.objetivoSemanal,
      objetivoMensual: objetivoMensual ?? this.objetivoMensual,
      objetivoAnual: objetivoAnual ?? this.objetivoAnual,
      creado: creado,
    );
  }

  static List<int> _listaInt(dynamic valor) {
    if (valor == null) return const [];
    return (valor as List).map((e) => e as int).toList();
  }

  static String? _fechaAIso(DateTime? fecha) {
    if (fecha == null) return null;
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
