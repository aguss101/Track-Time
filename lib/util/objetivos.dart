class ObjetivosCalculados {
  final int? diario;
  final int? semanal;
  final int? mensual;
  final int? anual;

  const ObjetivosCalculados({
    this.diario,
    this.semanal,
    this.mensual,
    this.anual,
  });
}

class CalculoObjetivos {
  CalculoObjetivos._();

  static const double _defaultDps = 5;

  static ObjetivosCalculados completar({
    int? diario,
    int? semanal,
    int? mensual,
    int? anual,
    int? cantidadDiasSemana,
    int diasSeleccionados = 0,
  }) {
    final dados = <int?>[diario, semanal, mensual, anual];
    if (dados.every((v) => v == null)) {
      return const ObjetivosCalculados();
    }

    final dps = _resolverDps(
      diario: diario,
      semanal: semanal,
      mensual: mensual,
      anual: anual,
      cantidadDiasSemana: cantidadDiasSemana,
      diasSeleccionados: diasSeleccionados,
    );

    double subir(int i) => i == 0
        ? dps
        : i == 1
        ? 4
        : 12;

    int convertir(int desde, int hasta) {
      var valor = dados[desde]!.toDouble();
      if (hasta > desde) {
        for (var i = desde; i < hasta; i++) {
          valor *= subir(i);
        }
      } else {
        for (var i = desde - 1; i >= hasta; i--) {
          valor /= subir(i);
        }
      }
      return valor.round();
    }

    final salida = List<int?>.from(dados);
    for (var i = 0; i < 4; i++) {
      if (salida[i] != null) continue;
      int? mejor;
      var mejorDistancia = 99;
      for (var j = 0; j < 4; j++) {
        if (dados[j] == null) continue;
        final distancia = (j - i).abs();
        if (distancia < mejorDistancia ||
            (distancia == mejorDistancia && j > (mejor ?? -1))) {
          mejorDistancia = distancia;
          mejor = j;
        }
      }
      if (mejor != null) salida[i] = convertir(mejor, i);
    }

    return ObjetivosCalculados(
      diario: salida[0],
      semanal: salida[1],
      mensual: salida[2],
      anual: salida[3],
    );
  }

  static double _resolverDps({
    int? diario,
    int? semanal,
    int? mensual,
    int? anual,
    int? cantidadDiasSemana,
    int diasSeleccionados = 0,
  }) {
    if (cantidadDiasSemana != null && cantidadDiasSemana > 0) {
      return cantidadDiasSemana.toDouble();
    }
    if (diasSeleccionados > 0) {
      return diasSeleccionados.toDouble();
    }
    if (diario != null && diario > 0) {
      final inferencias = <double>[];
      if (semanal != null) inferencias.add(semanal / diario);
      if (mensual != null) inferencias.add(mensual / (diario * 4));
      if (anual != null) inferencias.add(anual / (diario * 48));
      if (inferencias.isNotEmpty) {
        final suma = inferencias.reduce((a, b) => a + b);
        return suma / inferencias.length;
      }
    }
    return _defaultDps;
  }
}
