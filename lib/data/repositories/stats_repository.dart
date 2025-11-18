import '../database/app_database.dart';
import '../database/daos/stats_dao.dart';
import '../models/user_stats.dart';
import '../models/genre_stats.dart';

/// Repositorio para gestionar estadísticas
class StatsRepository {
  final StatsDao _statsDao;

  StatsRepository(AppDatabase database) : _statsDao = StatsDao(database);

  // ====== USER STATS ======

  /// Obtener estadísticas del usuario
  Future<UserStats?> getUserStats() async {
    final data = await _statsDao.getUserStats();
    return data != null ? _mapToUserStats(data) : null;
  }

  /// Actualizar estadísticas del usuario
  Future<bool> updateUserStats(UserStats stats) async {
    return await _statsDao.updateUserStats(_mapToUserStatsTableData(stats));
  }

  /// Agregar tiempo de escucha
  Future<void> addListeningTime(int milliseconds) async {
    await _statsDao.addListeningTime(milliseconds);
  }

  /// Incrementar contador de tracks reproducidos
  Future<void> incrementTracksPlayed() async {
    await _statsDao.incrementTracksPlayed();
  }

  /// Actualizar racha
  Future<void> updateStreak(int newStreak) async {
    await _statsDao.updateStreak(newStreak);
  }

  /// Añadir XP
  Future<void> addXP(int xp) async {
    await _statsDao.addXP(xp);
  }

  /// Calcular y actualizar racha automáticamente
  Future<void> calculateStreak() async {
    final stats = await getUserStats();
    if (stats == null) return;

    final now = DateTime.now();
    final lastDate = stats.lastListeningDate;
    final daysDiff = now.difference(lastDate).inDays;

    if (daysDiff == 0) {
      // Mismo día, no hacer nada
      return;
    } else if (daysDiff == 1) {
      // Día consecutivo, incrementar streak
      await updateStreak(stats.currentStreakDays + 1);
    } else {
      // Se rompió la racha, reiniciar a 1
      await updateStreak(1);
    }
  }

  /// Observar estadísticas del usuario (Stream)
  Stream<UserStats?> watchUserStats() {
    return _statsDao.watchUserStats().map(
          (data) => data != null ? _mapToUserStats(data) : null,
    );
  }

  // ====== GENRE STATS ======

  /// Obtener todas las estadísticas de géneros
  Future<List<GenreStats>> getAllGenreStats() async {
    final data = await _statsDao.getAllGenreStats();
    return data.map(_mapToGenreStats).toList();
  }

  /// Obtener estadísticas de un género
  Future<GenreStats?> getGenreStats(String genre) async {
    final data = await _statsDao.getGenreStats(genre);
    return data != null ? _mapToGenreStats(data) : null;
  }

  /// Obtener top géneros
  Future<List<GenreStats>> getTopGenres({int limit = 5}) async {
    final data = await _statsDao.getTopGenres(limit: limit);
    return data.map(_mapToGenreStats).toList();
  }

  /// Agregar tiempo de escucha a un género
  Future<void> addGenreListeningTime(String genre, int milliseconds) async {
    await _statsDao.addGenreListeningTime(genre, milliseconds);
  }

  /// Observar top géneros (Stream)
  Stream<List<GenreStats>> watchTopGenres({int limit = 5}) {
    return _statsDao.watchTopGenres(limit: limit).map(
          (data) => data.map(_mapToGenreStats).toList(),
    );
  }

  // ====== MAPPERS ======

  UserStats _mapToUserStats(UserStatsTableData data) {
    return UserStats(
      id: data.id,
      totalListeningMs: data.totalListeningMs,
      totalTracksPlayed: data.totalTracksPlayed,
      currentStreakDays: data.currentStreakDays,
      lastListeningDate: data.lastListeningDate,
      level: data.level,
      totalXP: data.totalXP,
    );
  }

  UserStatsTableData _mapToUserStatsTableData(UserStats stats) {
    return UserStatsTableData(
      id: stats.id,
      totalListeningMs: stats.totalListeningMs,
      totalTracksPlayed: stats.totalTracksPlayed,
      currentStreakDays: stats.currentStreakDays,
      lastListeningDate: stats.lastListeningDate,
      level: stats.level,
      totalXP: stats.totalXP,
    );
  }

  GenreStats _mapToGenreStats(GenreStatsTableData data) {
    return GenreStats(
      id: data.id,
      genre: data.genre,
      totalListeningMs: data.totalListeningMs,
    );
  }
}
