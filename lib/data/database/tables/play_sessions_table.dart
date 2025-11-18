import 'package:drift/drift.dart';
import 'tracks_table.dart';

/// Tabla de sesiones de reproducción
class PlaySessionsTable extends Table {
  // PRIMARY KEY
  IntColumn get id => integer().autoIncrement()();

  // FOREIGN KEY a tracks
  IntColumn get trackId => integer().references(TracksTable, #id)();

  // Tiempos de sesión
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  // Tiempo reproducido en milisegundos
  IntColumn get playedMs => integer()();

  // Si fue skipped o no
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();

  // Posición donde se hizo skip (si aplica)
  IntColumn get skipPositionMs => integer().nullable()();

  // Fuente de reproducción: manual, shuffle, playlist, session, album, artist, search
  TextColumn get source => text()();

  @override
  String get tableName => 'play_sessions';
}
