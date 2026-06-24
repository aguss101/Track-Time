enum Periodo { diario, semanal, mensual, anual }

class Metrica {
  final Periodo periodo;
  final int acumulado;
  final int restante;
  final int excedente;

  final int? diasRestantes;
  final bool? sinDiasAsignados;
  final int? promedioDiarioRestante;

  final int? semanasRestantes;
  final int? promedioSemanalRestante;

  const Metrica({
    required this.periodo,
    required this.acumulado,
    required this.restante,
    required this.excedente,
    this.diasRestantes,
    this.sinDiasAsignados,
    this.promedioDiarioRestante,
    this.semanasRestantes,
    this.promedioSemanalRestante,
  });

  factory Metrica.fromJson(Periodo periodo, Map<String, dynamic> json) {
    int leer(String k) => (json[k] as num?)?.toInt() ?? 0;
    return Metrica(
      periodo: periodo,
      acumulado: leer('acumulado'),
      restante: leer('restante'),
      excedente: leer('excedente'),
      diasRestantes: json['dias_restantes'] == null
          ? null
          : leer('dias_restantes'),
      sinDiasAsignados: json['sin_dias_asignados'] as bool?,
      promedioDiarioRestante: json['promedio_diario_restante'] == null
          ? null
          : leer('promedio_diario_restante'),
      semanasRestantes: json['semanas_restantes'] == null
          ? null
          : leer('semanas_restantes'),
      promedioSemanalRestante: json['promedio_semanal_restante'] == null
          ? null
          : leer('promedio_semanal_restante'),
    );
  }
}
