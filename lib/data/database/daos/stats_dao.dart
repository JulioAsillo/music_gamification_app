import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_stats_table.dart';
import '../tables/genre_stats_table.dart';

part 'stats_dao.g.dart';

/// DAO para gestionar estadísticas (usuario y géneros)
@DriftAccessor(tables: [UserStatsTable, GenreStatsTable])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(AppDatabase db) : super(db);

  // ====== USER STATS ======

  /// Obtener estadísticas del usuario
  Future<UserStatsTableData?> getUserStats() {
    return (select(userStatsTable)..where((s) => s.id.equals(1)))
        .getSingleOrNull();
  }

  /// Actualizar estadísticas del usuario
  Future<bool> updateUserStats(UserStatsTableData stats) {
    return update(userStatsTable).replace(stats);
  }

  /// Incrementar tiempo total de escucha
  Future<void> addListeningTime(int milliseconds) async {
    final stats = await getUserStats();
    if (stats != null) {
      await (update(userStatsTable)..where((s) => s.id.equals(1))).write(
        UserStatsTableCompanion(
          totalListeningMs: Value(stats.totalListeningMs + milliseconds),
          lastListeningDate: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Incrementar tracks reproducidos
  Future<void> incrementTracksPlayed() async {
    final stats = await getUserStats();
    if (stats != null) {
      await (update(userStatsTable)..where((s) => s.id.equals(1))).write(
        UserStatsTableCompanion(
          totalTracksPlayed: Value(stats.totalTracksPlayed + 1),
        ),
      );
    }
  }

  /// Actualizar racha (streak)
  Future<void> updateStreak(int newStreak) async {
    await (update(userStatsTable)..where((s) => s.id.equals(1))).write(
      UserStatsTableCompanion(
        currentStreakDays: Value(newStreak),
        lastListeningDate: Value(DateTime.now()),
      ),
    );
  }

  /// Añadir XP
  Future<void> addXP(int xp) async {
    final stats = await getUserStats();
    if (stats != null) {
      final newTotalXP = stats.totalXP + xp;
      // Calcular nuevo nivel: nivel = sqrt(XP / 1000) + 1
      final newLevel = sqrt(newTotalXP / 1000).floor() + 1;

      await (update(userStatsTable)..where((s) => s.id.equals(1))).write(
        UserStatsTableCompanion(
          totalXP: Value(newTotalXP),
          level: Value(newLevel),
        ),
      );
    }
  }

  /// Observar estadísticas del usuario (Stream)
  Stream<UserStatsTableData?> watchUserStats() {
    return (select(userStatsTable)..where((s) => s.id.equals(1)))
        .watchSingleOrNull();
  }

  // ====== GENRE STATS ======

  /// Obtener todas las estadísticas de géneros
  Future<List<GenreStatsTableData>> getAllGenreStats() {
    return (select(genreStatsTable)
      ..orderBy([(g) => OrderingTerm.desc(g.totalListeningMs)]))
        .get();
  }

  /// Obtener estadísticas de un género específico
  Future<GenreStatsTableData?> getGenreStats(String genre) {
    return (select(genreStatsTable)..where((g) => g.genre.equals(genre)))
        .getSingleOrNull();
  }

  /// Obtener top N géneros
  Future<List<GenreStatsTableData>> getTopGenres({int limit = 5}) {
    return (select(genreStatsTable)
      ..orderBy([(g) => OrderingTerm.desc(g.totalListeningMs)])
      ..limit(limit))
        .get();
  }

  /// Añadir tiempo de escucha a un género
  Future<void> addGenreListeningTime(String genre, int milliseconds) async {
    final existing = await getGenreStats(genre);

    if (existing != null) {
      // Actualizar existente
      await (update(genreStatsTable)..where((g) => g.genre.equals(genre)))
          .write(
        GenreStatsTableCompanion(
          totalListeningMs: Value(existing.totalListeningMs + milliseconds),
        ),
      );
    } else {
      // Crear nuevo
      await into(genreStatsTable).insert(
        GenreStatsTableCompanion.insert(
          genre: genre,
          totalListeningMs: Value(milliseconds),
        ),
      );
    }
  }

  /// Eliminar estadísticas de un género
  Future<int> deleteGenreStats(String genre) {
    return (delete(genreStatsTable)..where((g) => g.genre.equals(genre))).go();
  }

  /// Observar top géneros (Stream)
  Stream<List<GenreStatsTableData>> watchTopGenres({int limit = 5}) {
    return (select(genreStatsTable)
      ..orderBy([(g) => OrderingTerm.desc(g.totalListeningMs)])
      ..limit(limit))
        .watch();
  }
}
