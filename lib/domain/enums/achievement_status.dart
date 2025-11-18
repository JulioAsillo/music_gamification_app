/// Estado de un logro
enum AchievementStatus {
  /// Logro bloqueado (no cumple condiciones)
  locked,

  /// Logro en progreso
  inProgress,

  /// Logro desbloqueado
  unlocked,
}

extension AchievementStatusExtension on AchievementStatus {
  String get displayName {
    switch (this) {
      case AchievementStatus.locked:
        return 'Bloqueado';
      case AchievementStatus.inProgress:
        return 'En Progreso';
      case AchievementStatus.unlocked:
        return 'Desbloqueado';
    }
  }

  bool get isUnlocked => this == AchievementStatus.unlocked;
  bool get isLocked => this == AchievementStatus.locked;
  bool get isInProgress => this == AchievementStatus.inProgress;
}
