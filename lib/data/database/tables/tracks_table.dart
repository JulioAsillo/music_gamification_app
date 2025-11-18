import 'package:drift/drift.dart';

/// Tabla de canciones/tracks
class TracksTable extends Table {
  // PRIMARY KEY auto-incremental
  IntColumn get id => integer().autoIncrement()();

  // Información del archivo
  TextColumn get filePath => text().unique()();

  // Metadatos básicos
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  TextColumn get genre => text()();

  // Duración en milisegundos
  IntColumn get durationMs => integer()();

  // Fechas y uso
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  // Estadísticas
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get skipCount => integer().withDefault(const Constant(0))();

  // Preferencias
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  // Arte de portada (path local o null)
  TextColumn get coverArtPath => text().nullable()();

  @override
  String get tableName => 'tracks';
}
