/// Formatos de texto usados en las pantallas del rediseño.
abstract final class Fmt {
  /// Duración de una canción: `3:45`, o `1:02:10` si pasa de una hora.
  static String trackDuration(int milliseconds) {
    final d = Duration(milliseconds: milliseconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  /// Posición del reproductor a partir de un [Duration].
  static String position(Duration d) => trackDuration(d.inMilliseconds);

  /// Duración total de una lista: `1 h 50 min`, `42 min`, `0 min`.
  static String totalDuration(int milliseconds) {
    final d = Duration(milliseconds: milliseconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// Horas con un decimal: `48.6 h`.
  static String hours(int milliseconds) => '${(milliseconds / 3600000).toStringAsFixed(1)} h';

  /// Separador de miles con coma, como en el diseño: `2,340`.
  static String thousands(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// `1 canción` / `12 canciones`.
  static String songs(int n) => '${thousands(n)} ${n == 1 ? 'canción' : 'canciones'}';

  /// Saludo según la hora local.
  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h >= 5 && h < 12) return 'Buenos días';
    if (h >= 12 && h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
