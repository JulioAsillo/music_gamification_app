import 'package:drift/drift.dart';

/// Tabla de estadísticas por género
class GenreStatsTable extends Table {
  // PRIMARY KEY
  IntColumn get id => integer().autoIncrement()();

  // Nombre del género (único)
  TextColumn get genre => text().unique()();

  // Tiempo total escuchado en milisegundos
  IntColumn get totalListeningMs => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'genre_stats';
}
