import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas
class AppDateUtils {
  AppDateUtils._();

  /// Formatea fecha a formato legible
  /// Ejemplo: "15 Nov 2025"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }

  /// Formatea fecha con hora
  /// Ejemplo: "15 Nov 2025, 14:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'es').format(date);
  }

  /// Formatea fecha relativa
  /// Ejemplo: "Hace 2 días", "Hoy", "Ayer"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return 'Hace ${difference.inMinutes} minutos';
      } else {
        return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
      }
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    }
  }

  /// Calcula streak (racha) de días
  /// Retorna true si la fecha es del día anterior
  static bool isConsecutiveDay(DateTime lastDate, DateTime currentDate) {
    final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final difference = currentDateOnly.difference(lastDateOnly).inDays;
    return difference == 1;
  }

  /// Verifica si es el mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Retorna el día de la semana
  /// Ejemplo: "Lunes"
  static String getDayOfWeek(DateTime date) {
    final weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return weekdays[date.weekday - 1];
  }

  /// Retorna el día de la semana abreviado
  /// Ejemplo: "L", "M", "X"
  static String getDayOfWeekShort(DateTime date) {
    final weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return weekdays[date.weekday - 1];
  }

  /// Obtiene las fechas de los últimos N días
  static List<DateTime> getLastNDays(int days) {
    final now = DateTime.now();
    return List.generate(
      days,
          (index) => now.subtract(Duration(days: days - 1 - index)),
    );
  }
}
