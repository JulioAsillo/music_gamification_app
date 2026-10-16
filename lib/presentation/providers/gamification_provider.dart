import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/achievement.dart';
import '../../data/models/track.dart';
import '../../domain/enums/achievement_status.dart';
import '../../domain/services/gamification_service.dart';
import 'achievements_provider.dart';
import 'database_provider.dart';

/// Servicio de gamificación (singleton). Al crearse siembra los logros.
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final service = GamificationService(ref.watch(appDatabaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Eventos de XP / logros / nivel para mostrar feedback en la UI.
final gamificationEventsProvider = StreamProvider<GamificationEvent>((ref) {
  return ref.watch(gamificationServiceProvider).events;
});

/// Minutos escuchados por día de la semana actual (lunes → domingo).
final weeklyListeningProvider = StreamProvider<List<int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final nextMonday = monday.add(const Duration(days: 7));

  final query = db.select(db.playSessionsTable)
    ..where((s) => s.startTime.isBiggerOrEqualValue(monday) & s.startTime.isSmallerThanValue(nextMonday));

  return query.watch().map((sessions) {
    final ms = List<int>.filled(7, 0);
    for (final s in sessions) {
      ms[s.startTime.weekday - 1] += s.playedMs;
    }
    return ms.map((v) => v ~/ 60000).toList();
  });
});

/// Últimas canciones escuchadas (para "Continuar escuchando").
final recentlyPlayedProvider = StreamProvider<List<Track>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.tracksTable)
    ..where((t) => t.lastPlayedAt.isNotNull())
    ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
    ..limit(10);
  return query.watch().map((rows) => rows.map(Track.fromDatabase).toList());
});

/// Top 5 géneros por tiempo escuchado: (género, minutos).
final topGenresMinutesProvider = StreamProvider<List<(String, int)>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.genreStatsTable)
    ..orderBy([(g) => OrderingTerm.desc(g.totalListeningMs)])
    ..limit(5);
  return query.watch().map((rows) => [for (final g in rows) (g.genre, g.totalListeningMs ~/ 60000)]);
});

/// Logros ordenados: desbloqueados primero, luego por progreso.
final sortedAchievementsProvider = Provider<AsyncValue<List<Achievement>>>((ref) {
  ref.watch(gamificationServiceProvider); // asegura que los logros existan
  return ref.watch(watchAllAchievementsProvider).whenData((list) {
    final sorted = List<Achievement>.of(list)
      ..sort((a, b) {
        final ua = a.status == AchievementStatus.unlocked ? 0 : 1;
        final ub = b.status == AchievementStatus.unlocked ? 0 : 1;
        if (ua != ub) return ua - ub;
        return b.progressPercentage.compareTo(a.progressPercentage);
      });
    return sorted;
  });
});

/// El logro bloqueado más cercano a completarse (tarjeta "Próximo logro").
final nextAchievementProvider = Provider<Achievement?>((ref) {
  final list = ref.watch(sortedAchievementsProvider).value ?? const <Achievement>[];
  Achievement? best;
  for (final a in list) {
    if (a.status == AchievementStatus.unlocked) continue;
    if (best == null ||
        a.progressPercentage > best.progressPercentage ||
        (a.progressPercentage == best.progressPercentage && a.targetProgress < best.targetProgress)) {
      best = a;
    }
  }
  return best;
});
