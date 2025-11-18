import 'package:drift/drift.dart';

/// Tabla de estadísticas globales del usuario (solo 1 fila)
class UserStatsTable extends Table {
  // ID siempre será 1 (única fila)
  IntColumn get id => integer().withDefault(const Constant(1))();

  // Estadísticas acumuladas
  IntColumn get totalListeningMs => integer().withDefault(const Constant(0))();
  IntColumn get totalTracksPlayed => integer().withDefault(const Constant(0))();

  // Racha de días
  IntColumn get currentStreakDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastListeningDate => dateTime()();

  // Gamificación
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get totalXP => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'user_stats';

  @override
  Set<Column> get primaryKey => {id};
}
