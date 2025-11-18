/// Formateador de duración para mostrar tiempos de música
class DurationFormatter {
  DurationFormatter._();

  /// Convierte milisegundos a formato MM:SS
  /// Ejemplo: 185000 ms → "3:05"
  static String formatMilliseconds(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    return formatDuration(duration);
  }

  /// Convierte Duration a formato MM:SS o HH:MM:SS
  /// Ejemplo: Duration(minutes: 3, seconds: 5) → "3:05"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Formatea duración larga (para estadísticas)
  /// Ejemplo: 214 horas → "214 hrs"
  /// Ejemplo: 42 minutos → "42 min"
  static String formatLongDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours} hrs';
    } else if (minutes > 0) {
      return '${minutes} min';
    } else {
      return '${duration.inSeconds} seg';
    }
  }

  /// Formatea duración detallada
  /// Ejemplo: 214h 30m → "214h 30m"
  static String formatDetailedDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Convierte segundos a formato legible
  /// Ejemplo: 7200 → "2 horas"
  static String formatSecondsToWords(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs $minutes min';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (minutes > 0) {
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return '$seconds ${seconds == 1 ? 'segundo' : 'segundos'}';
    }
  }

  /// Progreso de reproducción (para barras)
  /// Retorna valor entre 0.0 y 1.0
  static double calculateProgress(int currentMs, int totalMs) {
    if (totalMs <= 0) return 0.0;
    return (currentMs / totalMs).clamp(0.0, 1.0);
  }
}
