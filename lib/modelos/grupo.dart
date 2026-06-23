/// Modelo de la tabla `grupos`.
/// `grupos(id SERIAL PK, nombre TEXT, color TEXT)`
class Grupo {
  final int id;
  final String nombre;
  final String? color;

  const Grupo({
    required this.id,
    required this.nombre,
    this.color,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      color: json['color'] as String?,
    );
  }

  /// Para INSERT/PATCH no se envía `id` (lo asigna el SERIAL de la DB).
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (color != null) 'color': color,
    };
  }

  Grupo copyWith({String? nombre, String? color}) {
    return Grupo(
      id: id,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
    );
  }
}
