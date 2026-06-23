/// Helpers de formateo de tiempo. Segundos → texto.
class Formato {
  Formato._();

  /// `HH:MM:SS` — usado en el cronómetro. Soporta más de 24 horas.
  static String relojCompleto(int segundos) {
    if (segundos < 0) segundos = 0;
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    return '${_dos(h)}:${_dos(m)}:${_dos(s)}';
  }

  /// Forma compacta legible: `2h 30m`, `45m`, `30s`.
  /// Para mostrar acumulados y objetivos en cards/métricas.
  static String compacto(int segundos) {
    if (segundos <= 0) return '0m';
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
