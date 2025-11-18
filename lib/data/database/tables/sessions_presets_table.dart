import 'package:drift/drift.dart';

/// Tabla de sesiones guardadas (gym, estudio, etc.)
class SessionPresetsTable extends Table {
  // PRIMARY KEY
  IntColumn get id => integer().autoIncrement()();

  // Nombre de la sesión
  TextColumn get name => text()();

  // Tipo: gym, estudio, chill, etc.
  TextColumn get type => text()();

  // IDs de tracks separados por comas (ej: "1,5,8,12")
  TextColumn get trackIds => text()();

  // Fechas
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  String get tableName => 'session_presets';
}
