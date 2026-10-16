import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/play_sessions_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/tracks_repository.dart';
import 'database_provider.dart';

part 'repositories_provider.g.dart';

/// Provider del repositorio de tracks
@Riverpod(keepAlive: true)
TracksRepository tracksRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return TracksRepository(database);
}

/// Provider del repositorio de sesiones de reproducción
@Riverpod(keepAlive: true)
PlaySessionsRepository playSessionsRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return PlaySessionsRepository(database);
}

/// Provider del repositorio de estadísticas
@Riverpod(keepAlive: true)
StatsRepository statsRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return StatsRepository(database);
}

/// Provider del repositorio de logros
@Riverpod(keepAlive: true)
AchievementsRepository achievementsRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return AchievementsRepository(database);
}
