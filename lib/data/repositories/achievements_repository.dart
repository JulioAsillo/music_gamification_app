import '../../domain/enums/achievement_status.dart';
import '../../domain/enums/achievement_type.dart';
import '../database/app_database.dart';
import '../database/daos/achievements_dao.dart';
import '../models/achievement.dart';
import 'package:drift/drift.dart';

/// Repositorio para gestionar logros
class AchievementsRepository {
  final AchievementsDao _achievementsDao;

  AchievementsRepository(AppDatabase database)
      : _achievementsDao = AchievementsDao(database);

  /// Obtener todos los logros
  Future<List<Achievement>> getAllAchievements() async {
    final data = await _achievementsDao.getAllAchievements();
    return data.map(_mapToAchievement).toList();
  }

  /// Obtener logro por ID
  Future<Achievement?> getAchievementById(String id) async {
    final data = await _achievementsDao.getAchievementById(id);
    return data != null ? _mapToAchievement(data) : null;
  }

  /// Obtener logros desbloqueados
  Future<List<Achievement>> getUnlockedAchievements() async {
    final data = await _achievementsDao.getUnlockedAchievements();
    return data.map(_mapToAchievement).toList();
  }

  /// Obtener logros bloqueados
  Future<List<Achievement>> getLockedAchievements() async {
    final data = await _achievementsDao.getLockedAchievements();
    return data.map(_mapToAchievement).toList();
  }

  /// Obtener logros en progreso
  Future<List<Achievement>> getInProgressAchievements() async {
    final data = await _achievementsDao.getInProgressAchievements();
    return data.map(_mapToAchievement).toList();
  }

  /// Obtener logros por tipo
  Future<List<Achievement>> getAchievementsByType(AchievementType type) async {
    final data = await _achievementsDao.getAchievementsByType(type.name);
    return data.map(_mapToAchievement).toList();
  }

  /// Agregar un logro
  Future<void> addAchievement(Achievement achievement) async {
    await _achievementsDao.insertAchievement(_mapToCompanion(achievement));
  }

  /// Agregar múltiples logros
  Future<void> addAchievements(List<Achievement> achievements) async {
    final companions = achievements.map(_mapToCompanion).toList();
    await _achievementsDao.insertAchievements(companions);
  }

  /// Actualizar un logro
  Future<bool> updateAchievement(Achievement achievement) async {
    return await _achievementsDao.updateAchievement(
      _mapToTableData(achievement),
    );
  }

  /// Actualizar progreso de un logro
  Future<void> updateProgress(String achievementId, int newProgress) async {
    await _achievementsDao.updateProgress(achievementId, newProgress);

    // Verificar si se debe desbloquear
    final achievement = await getAchievementById(achievementId);
    if (achievement != null && achievement.isCompleted) {
      await unlockAchievement(achievementId);
    }
  }

  /// Desbloquear un logro
  Future<void> unlockAchievement(String achievementId) async {
    await _achievementsDao.unlockAchievement(achievementId);
  }

  /// Contar logros desbloqueados
  Future<int> getUnlockedCount() async {
    return await _achievementsDao.countUnlockedAchievements();
  }

  /// Observar todos los logros (Stream)
  Stream<List<Achievement>> watchAllAchievements() {
    return _achievementsDao.watchAllAchievements().map(
          (data) => data.map(_mapToAchievement).toList(),
    );
  }

  /// Observar logros desbloqueados (Stream)
  Stream<List<Achievement>> watchUnlockedAchievements() {
    return _achievementsDao.watchUnlockedAchievements().map(
          (data) => data.map(_mapToAchievement).toList(),
    );
  }

  // ====== MAPPERS ======

  Achievement _mapToAchievement(AchievementsTableData data) {
    return Achievement(
      id: data.id,
      title: data.title,
      description: data.description,
      type: AchievementType.values.firstWhere(
            (e) => e.name == data.type,
        orElse: () => AchievementType.special,
      ),
      status: AchievementStatus.values.firstWhere(
            (e) => e.name == data.status,
        orElse: () => AchievementStatus.locked,
      ),
      unlockedAt: data.unlockedAt,
      currentProgress: data.currentProgress,
      targetProgress: data.targetProgress,
      xpReward: data.xpReward,
    );
  }

  AchievementsTableCompanion _mapToCompanion(Achievement achievement) {
    return AchievementsTableCompanion(
      id: Value(achievement.id),
      title: Value(achievement.title),
      description: Value(achievement.description),
      type: Value(achievement.type.name),
      status: Value(achievement.status.name),
      unlockedAt: Value(achievement.unlockedAt),
      currentProgress: Value(achievement.currentProgress),
      targetProgress: Value(achievement.targetProgress),
      xpReward: Value(achievement.xpReward),
    );
  }

  AchievementsTableData _mapToTableData(Achievement achievement) {
    return AchievementsTableData(
      id: achievement.id,
      title: achievement.title,
      description: achievement.description,
      type: achievement.type.name,
      status: achievement.status.name,
      unlockedAt: achievement.unlockedAt,
      currentProgress: achievement.currentProgress,
      targetProgress: achievement.targetProgress,
      xpReward: achievement.xpReward,
    );
  }
}
