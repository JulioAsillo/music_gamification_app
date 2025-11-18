import '../../domain/enums/playback_source.dart';
import '../database/app_database.dart';
import '../database/daos/play_sessions_dao.dart';
import '../models/play_session.dart';
import 'package:drift/drift.dart';

/// Repositorio para gestionar sesiones de reproducción
class PlaySessionsRepository {
  final PlaySessionsDao _sessionsDao;

  PlaySessionsRepository(AppDatabase database)
      : _sessionsDao = PlaySessionsDao(database);

  /// Agregar una sesión
  Future<int> addSession(PlaySession session) async {
    return await _sessionsDao.insertSession(_mapToCompanion(session));
  }

  /// Obtener todas las sesiones
  Future<List<PlaySession>> getAllSessions() async {
    final data = await _sessionsDao.getAllSessions();
    return data.map(_mapToPlaySession).toList();
  }

  /// Obtener sesiones por track
  Future<List<PlaySession>> getSessionsByTrackId(int trackId) async {
    final data = await _sessionsDao.getSessionsByTrackId(trackId);
    return data.map(_mapToPlaySession).toList();
  }

  /// Obtener sesiones por fecha
  Future<List<PlaySession>> getSessionsByDate(DateTime date) async {
    final data = await _sessionsDao.getSessionsByDate(date);
    return data.map(_mapToPlaySession).toList();
  }

  /// Obtener sesiones en rango de fechas
  Future<List<PlaySession>> getSessionsBetweenDates(
      DateTime start,
      DateTime end,
      ) async {
    final data = await _sessionsDao.getSessionsBetweenDates(start, end);
    return data.map(_mapToPlaySession).toList();
  }

  /// Obtener sesiones recientes
  Future<List<PlaySession>> getRecentSessions({int limit = 10}) async {
    final data = await _sessionsDao.getRecentSessions(limit: limit);
    return data.map(_mapToPlaySession).toList();
  }

  /// Obtener tiempo total de escucha
  Future<int> getTotalListeningTime() async {
    return await _sessionsDao.getTotalListeningTime();
  }

  /// Obtener tiempo de escucha en rango de fechas
  Future<int> getListeningTimeBetweenDates(
      DateTime start,
      DateTime end,
      ) async {
    return await _sessionsDao.getListeningTimeBetweenDates(start, end);
  }

  /// Obtener tiempo de escucha de hoy
  Future<int> getTodayListeningTime() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await _sessionsDao.getListeningTimeBetweenDates(
      startOfDay,
      endOfDay,
    );
  }

  /// Obtener tiempo de escucha de esta semana
  Future<int> getWeekListeningTime() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return await _sessionsDao.getListeningTimeBetweenDates(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      now,
    );
  }

  /// Obtener tracks más reproducidos
  Future<List<Map<String, dynamic>>> getMostPlayedTracks({
    int limit = 10,
  }) async {
    return await _sessionsDao.getMostPlayedTracks(limit: limit);
  }

  /// Contar total de sesiones
  Future<int> getSessionsCount() async {
    return await _sessionsDao.countSessions();
  }

  /// Eliminar sesiones antiguas
  Future<int> deleteOldSessions({int daysOld = 90}) async {
    return await _sessionsDao.deleteOldSessions(daysOld: daysOld);
  }

  /// Observar sesiones recientes (Stream)
  Stream<List<PlaySession>> watchRecentSessions({int limit = 10}) {
    return _sessionsDao.watchRecentSessions(limit: limit).map(
          (data) => data.map(_mapToPlaySession).toList(),
    );
  }

  // ====== MAPPERS ======

  PlaySession _mapToPlaySession(PlaySessionsTableData data) {
    return PlaySession(
      id: data.id,
      trackId: data.trackId,
      startTime: data.startTime,
      endTime: data.endTime,
      playedMs: data.playedMs,
      skipped: data.skipped,
      skipPositionMs: data.skipPositionMs,
      source: PlaybackSource.values.firstWhere(
            (e) => e.name == data.source,
        orElse: () => PlaybackSource.manual,
      ),
    );
  }

  PlaySessionsTableCompanion _mapToCompanion(PlaySession session) {
    return PlaySessionsTableCompanion(
      id: session.id != null ? Value(session.id!) : const Value.absent(),
      trackId: Value(session.trackId),
      startTime: Value(session.startTime),
      endTime: Value(session.endTime),
      playedMs: Value(session.playedMs),
      skipped: Value(session.skipped),
      skipPositionMs: Value(session.skipPositionMs),
      source: Value(session.source.name),
    );
  }
}
