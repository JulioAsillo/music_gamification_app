import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/play_session.dart';
import 'repositories_provider.dart';

part 'play_sessions_provider.g.dart';

/// Provider para obtener sesiones recientes
@riverpod
Future<List<PlaySession>> recentSessions(
    RecentSessionsRef ref, {
      int limit = 10,
    }) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getRecentSessions(limit: limit);
}

/// Provider para obtener tiempo de escucha de hoy
@riverpod
Future<int> todayListeningTime(TodayListeningTimeRef ref) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getTodayListeningTime();
}

/// Provider para obtener tiempo de escucha de esta semana
@riverpod
Future<int> weekListeningTime(WeekListeningTimeRef ref) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getWeekListeningTime();
}

/// Provider para obtener tiempo total de escucha
@riverpod
Future<int> totalListeningTime(TotalListeningTimeRef ref) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getTotalListeningTime();
}

/// Provider para obtener sesiones por track
@riverpod
Future<List<PlaySession>> sessionsByTrackId(
    SessionsByTrackIdRef ref,
    int trackId,
    ) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getSessionsByTrackId(trackId);
}

/// Provider para obtener sesiones por fecha
@riverpod
Future<List<PlaySession>> sessionsByDate(
    SessionsByDateRef ref,
    DateTime date,
    ) async {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return await repository.getSessionsByDate(date);
}

/// Stream provider para observar sesiones recientes
@riverpod
Stream<List<PlaySession>> watchRecentSessions(
    WatchRecentSessionsRef ref, {
      int limit = 10,
    }) {
  final repository = ref.watch(playSessionsRepositoryProvider);
  return repository.watchRecentSessions(limit: limit);
}
