/// Tipos de logros disponibles en la gamificación
enum AchievementType {
  /// Relacionado con streak de días
  streak,

  /// Relacionado con tiempo total escuchado
  totalTime,

  /// Relacionado con completar álbumes
  albumComplete,

  /// Relacionado con explorar nuevos géneros
  exploration,

  /// Relacionado con cantidad de canciones
  songCount,

  /// Relacionado con escuchar de noche
  nightOwl,

  /// Relacionado con variedad de artistas
  artistDiversity,

  /// Logros especiales o de eventos
  special,
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.streak:
        return 'Racha';
      case AchievementType.totalTime:
        return 'Tiempo Total';
      case AchievementType.albumComplete:
        return 'Álbum Completo';
      case AchievementType.exploration:
        return 'Exploración';
      case AchievementType.songCount:
        return 'Cantidad de Canciones';
      case AchievementType.nightOwl:
        return 'Búho Nocturno';
      case AchievementType.artistDiversity:
        return 'Diversidad de Artistas';
      case AchievementType.special:
        return 'Especial';
    }
  }

  String get iconName {
    switch (this) {
      case AchievementType.streak:
        return 'local_fire_department';
      case AchievementType.totalTime:
        return 'schedule';
      case AchievementType.albumComplete:
        return 'album';
      case AchievementType.exploration:
        return 'explore';
      case AchievementType.songCount:
        return 'music_note';
      case AchievementType.nightOwl:
        return 'dark_mode';
      case AchievementType.artistDiversity:
        return 'people';
      case AchievementType.special:
        return 'star';
    }
  }
}
