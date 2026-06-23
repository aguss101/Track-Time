class Formato {
  Formato._();

  static String relojCompleto(int segundos) {
    if (segundos < 0) segundos = 0;
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    return '${_dos(h)}:${_dos(m)}:${_dos(s)}';
  }

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
