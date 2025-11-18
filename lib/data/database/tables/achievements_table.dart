import 'package:drift/drift.dart';

/// Tabla de logros
class AchievementsTable extends Table {
  // ID único del logro (ej: "streak_7_days")
  TextColumn get id => text()();

  // Información del logro
  TextColumn get title => text()();
  TextColumn get description => text()();

  // Tipo de logro: streak, totalTime, albumComplete, exploration, etc.
  TextColumn get type => text()();

  // Estado: locked, inProgress, unlocked
  TextColumn get status => text()();

  // Fecha de desbloqueo
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  // Progreso
  IntColumn get currentProgress => integer().withDefault(const Constant(0))();
  IntColumn get targetProgress => integer()();

  // Recompensa en XP
  IntColumn get xpReward => integer().withDefault(const Constant(100))();

  @override
  String get tableName => 'achievements';

  @override
  Set<Column> get primaryKey => {id};
}
