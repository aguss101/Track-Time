class Sesion {
  final int id;
  final int idActividad;
  final DateTime iniciada;
  final DateTime? finalizada;
  final int? duracion;

  const Sesion({
    required this.id,
    required this.idActividad,
    required this.iniciada,
    this.finalizada,
    this.duracion,
  });

  bool get estaActiva => finalizada == null;

  int transcurridos([DateTime? ahora]) {
    if (duracion != null) return duracion!;
    final ref = ahora ?? DateTime.now();
    return ref.difference(iniciada).inSeconds.clamp(0, 1 << 31);
  }

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      id: json['id'] as int,
      idActividad: json['id_actividad'] as int,
      iniciada: DateTime.parse(json['iniciada'] as String),
      finalizada: json['finalizada'] == null
          ? null
          : DateTime.parse(json['finalizada'] as String),
      duracion: json['duracion'] as int?,
    );
  }
}
