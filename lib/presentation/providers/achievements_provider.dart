import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/achievement.dart';
import '../../domain/enums/achievement_type.dart';
import 'repositories_provider.dart';

part 'achievements_provider.g.dart';

/// Provider para obtener todos los logros
@riverpod
Future<List<Achievement>> allAchievements(Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getAllAchievements();
}

/// Provider para obtener logros desbloqueados
@riverpod
Future<List<Achievement>> unlockedAchievements(Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getUnlockedAchievements();
}

/// Provider para obtener logros bloqueados
@riverpod
Future<List<Achievement>> lockedAchievements(Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getLockedAchievements();
}

/// Provider para obtener logros en progreso
@riverpod
Future<List<Achievement>> inProgressAchievements(Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getInProgressAchievements();
}

/// Provider para obtener logros por tipo
@riverpod
Future<List<Achievement>> achievementsByType(
    Ref ref,
    AchievementType type,
    ) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getAchievementsByType(type);
}

/// Provider para obtener cantidad de logros desbloqueados
@riverpod
Future<int> unlockedAchievementsCount(Ref ref) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  return await repository.getUnlockedCount();
}

/// Stream provider para observar todos los logros
@riverpod
Stream<List<Achievement>> watchAllAchievements(Ref ref) {
  final repository = ref.watch(achievementsRepositoryProvider);
  return repository.watchAllAchievements();
}

/// Stream provider para observar logros desbloqueados
@riverpod
Stream<List<Achievement>> watchUnlockedAchievements(Ref ref) {
  final repository = ref.watch(achievementsRepositoryProvider);
  return repository.watchUnlockedAchievements();
}
