import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/genre_stats.dart';
import '../../data/models/user_stats.dart';
import 'repositories_provider.dart';

part 'stats_provider.g.dart';

/// Provider para obtener estadísticas del usuario
@riverpod
Future<UserStats?> userStats(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getUserStats();
}

/// Stream provider para observar estadísticas del usuario
@riverpod
Stream<UserStats?> watchUserStats(Ref ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return repository.watchUserStats();
}

/// Provider para obtener top géneros
@riverpod
Future<List<GenreStats>> topGenres(Ref ref, {int limit = 5}) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getTopGenres(limit: limit);
}

/// Stream provider para observar top géneros
@riverpod
Stream<List<GenreStats>> watchTopGenres(Ref ref, {int limit = 5}) {
  final repository = ref.watch(statsRepositoryProvider);
  return repository.watchTopGenres(limit: limit);
}

/// Provider para obtener todas las estadísticas de géneros
@riverpod
Future<List<GenreStats>> allGenreStats(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getAllGenreStats();
}

/// Provider para obtener nivel del usuario
@riverpod
Future<int> userLevel(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  final stats = await repository.getUserStats();
  return stats?.level ?? 1;
}

/// Provider para obtener XP del usuario
@riverpod
Future<int> userXP(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  final stats = await repository.getUserStats();
  return stats?.totalXP ?? 0;
}

/// Provider para obtener racha actual
@riverpod
Future<int> currentStreak(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  final stats = await repository.getUserStats();
  return stats?.currentStreakDays ?? 0;
}

/// Provider para obtener tiempo total de escucha (en horas)
@riverpod
Future<double> totalListeningHours(Ref ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  final stats = await repository.getUserStats();
  return stats?.totalListeningHours ?? 0.0;
}
