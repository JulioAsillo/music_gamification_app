import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievements_table.dart';

part 'achievements_dao.g.dart';

/// DAO para gestionar logros
@DriftAccessor(tables: [AchievementsTable])
class AchievementsDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDaoMixin {
  AchievementsDao(AppDatabase db) : super(db);

  /// Obtener todos los logros
  Future<List<AchievementsTableData>> getAllAchievements() {
    return select(achievementsTable).get();
  }

  /// Obtener logro por ID
  Future<AchievementsTableData?> getAchievementById(String id) {
    return (select(achievementsTable)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtener logros desbloqueados
  Future<List<AchievementsTableData>> getUnlockedAchievements() {
    return (select(achievementsTable)..where((a) => a.status.equals('unlocked')))
        .get();
  }

  /// Obtener logros bloqueados
  Future<List<AchievementsTableData>> getLockedAchievements() {
    return (select(achievementsTable)..where((a) => a.status.equals('locked')))
        .get();
  }

  /// Obtener logros en progreso
  Future<List<AchievementsTableData>> getInProgressAchievements() {
    return (select(achievementsTable)
      ..where((a) => a.status.equals('inProgress')))
        .get();
  }

  /// Obtener logros por tipo
  Future<List<AchievementsTableData>> getAchievementsByType(String type) {
    return (select(achievementsTable)..where((a) => a.type.equals(type))).get();
  }

  /// Insertar un logro
  Future<void> insertAchievement(AchievementsTableCompanion achievement) {
    return into(achievementsTable).insert(achievement);
  }

  /// Insertar múltiples logros
  Future<void> insertAchievements(
      List<AchievementsTableCompanion> achievements) async {
    await batch((batch) {
      batch.insertAll(achievementsTable, achievements);
    });
  }

  /// Actualizar un logro
  Future<bool> updateAchievement(AchievementsTableData achievement) {
    return update(achievementsTable).replace(achievement);
  }

  /// Actualizar progreso de un logro
  Future<void> updateProgress(String achievementId, int newProgress) async {
    await (update(achievementsTable)..where((a) => a.id.equals(achievementId)))
        .write(
      AchievementsTableCompanion(
        currentProgress: Value(newProgress),
      ),
    );
  }

  /// Desbloquear un logro
  Future<void> unlockAchievement(String achievementId) async {
    await (update(achievementsTable)..where((a) => a.id.equals(achievementId)))
        .write(
      AchievementsTableCompanion(
        status: const Value('unlocked'),
        unlockedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Contar logros desbloqueados
  Future<int> countUnlockedAchievements() async {
    final count = achievementsTable.id.count();
    final query = selectOnly(achievementsTable)
      ..addColumns([count])
      ..where(achievementsTable.status.equals('unlocked'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Observar todos los logros (Stream)
  Stream<List<AchievementsTableData>> watchAllAchievements() {
    return select(achievementsTable).watch();
  }

  /// Observar logros desbloqueados (Stream)
  Stream<List<AchievementsTableData>> watchUnlockedAchievements() {
    return (select(achievementsTable)
      ..where((a) => a.status.equals('unlocked')))
        .watch();
  }
}
