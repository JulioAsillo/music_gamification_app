import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/play_sessions_table.dart';

part 'play_sessions_dao.g.dart';

/// DAO para gestionar sesiones de reproducción
@DriftAccessor(tables: [PlaySessionsTable])
class PlaySessionsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaySessionsDaoMixin {
  PlaySessionsDao(AppDatabase db) : super(db);

  /// Insertar una sesión
  Future<int> insertSession(PlaySessionsTableCompanion session) {
    return into(playSessionsTable).insert(session);
  }

  /// Obtener todas las sesiones
  Future<List<PlaySessionsTableData>> getAllSessions() {
    return select(playSessionsTable).get();
  }

  /// Obtener sesiones por track ID
  Future<List<PlaySessionsTableData>> getSessionsByTrackId(int trackId) {
    return (select(playSessionsTable)..where((s) => s.trackId.equals(trackId)))
        .get();
  }

  /// Obtener sesiones por fecha
  Future<List<PlaySessionsTableData>> getSessionsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(playSessionsTable)
      ..where((s) =>
      s.startTime.isBiggerOrEqualValue(startOfDay) &
      s.startTime.isSmallerThanValue(endOfDay)))
        .get();
  }

  /// Obtener sesiones en un rango de fechas
  Future<List<PlaySessionsTableData>> getSessionsBetweenDates(
      DateTime start,
      DateTime end,
      ) {
    return (select(playSessionsTable)
      ..where((s) =>
      s.startTime.isBiggerOrEqualValue(start) &
      s.startTime.isSmallerOrEqualValue(end)))
        .get();
  }

  /// Obtener últimas N sesiones
  Future<List<PlaySessionsTableData>> getRecentSessions({int limit = 10}) {
    return (select(playSessionsTable)
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)])
      ..limit(limit))
        .get();
  }

  /// Obtener sesiones skipped
  Future<List<PlaySessionsTableData>> getSkippedSessions() {
    return (select(playSessionsTable)..where((s) => s.skipped.equals(true)))
        .get();
  }

  /// Obtener total de tiempo reproducido (en milisegundos)
  Future<int> getTotalListeningTime() async {
    final sum = playSessionsTable.playedMs.sum();
    final query = selectOnly(playSessionsTable)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }

  /// Obtener tiempo reproducido en un rango de fechas
  Future<int> getListeningTimeBetweenDates(DateTime start, DateTime end) async {
    final sum = playSessionsTable.playedMs.sum();
    final query = selectOnly(playSessionsTable)
      ..addColumns([sum])
      ..where(
        playSessionsTable.startTime.isBiggerOrEqualValue(start) &
        playSessionsTable.startTime.isSmallerOrEqualValue(end),
      );
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }

  /// Contar total de sesiones
  Future<int> countSessions() async {
    final count = playSessionsTable.id.count();
    final query = selectOnly(playSessionsTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Obtener tracks más reproducidos (por cantidad de sesiones)
  Future<List<Map<String, dynamic>>> getMostPlayedTracks({int limit = 10}) async {
    final trackIdCol = playSessionsTable.trackId;
    final count = playSessionsTable.id.count();

    final query = selectOnly(playSessionsTable)
      ..addColumns([trackIdCol, count])
      ..groupBy([trackIdCol])
      ..orderBy([OrderingTerm.desc(count)])
      ..limit(limit);

    final results = await query.get();
    return results.map((row) {
      return {
        'trackId': row.read(trackIdCol),
        'playCount': row.read(count),
      };
    }).toList();
  }

  /// Eliminar sesiones antiguas (más de N días)
  Future<int> deleteOldSessions({int daysOld = 90}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(playSessionsTable)
      ..where((s) => s.startTime.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// Observar sesiones recientes (Stream)
  Stream<List<PlaySessionsTableData>> watchRecentSessions({int limit = 10}) {
    return (select(playSessionsTable)
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)])
      ..limit(limit))
        .watch();
  }
}
