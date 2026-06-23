/// Modelo de la tabla `actividades`.
///
/// `actividades(id, id_grupo FK, nombre, color, dias SMALLINT[],
///  meses SMALLINT[], objetivo_diario/semanal/mensual/anual INT,
///  creado TIMESTAMPTZ)`
///
/// - `dias`: [1..7] ISODOW (1=lunes ... 7=domingo). Opcional.
/// - `meses`: [1..12]. Opcional.
/// - objetivos en segundos. Opcionales (null = sin objetivo).
class Actividad {
  final int id;
  final int? idGrupo;
  final String nombre;
  final String color;
  final List<int> dias;
  final List<int> meses;
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
    this.meses = const [],
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
      meses: _listaInt(json['meses']),
      objetivoDiario: json['objetivo_diario'] as int?,
      objetivoSemanal: json['objetivo_semanal'] as int?,
      objetivoMensual: json['objetivo_mensual'] as int?,
      objetivoAnual: json['objetivo_anual'] as int?,
      creado: json['creado'] == null
          ? null
          : DateTime.parse(json['creado'] as String),
    );
  }

  /// Para INSERT/PATCH — no envía `id` ni `creado` (los maneja la DB).
  Map<String, dynamic> toJson() {
    return {
      'id_grupo': idGrupo,
      'nombre': nombre,
      'color': color,
      'dias': dias,
      'meses': meses,
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
    List<int>? meses,
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
      meses: meses ?? this.meses,
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
}
