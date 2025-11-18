/// Constantes globales de la aplicación
class AppConstants {
  AppConstants._();

  // 📱 APP INFO
  static const String appName = 'Music Gamification';
  static const String appVersion = '1.0.0';

  // 🎵 AUDIO
  static const List<String> supportedAudioFormats = [
    'mp3',
    'mp4',
    'm4a',
    'flac',
    'ogg',
    'wav',
    'opus',
  ];

  static const int minTrackDurationMs = 30000; // 30 segundos mínimo
  static const int skipThresholdMs = 30000; // Considerar skip si < 30s reproducidos

  // 📁 DIRECTORIOS DE ESCANEO
  static const List<String> musicDirectories = [
    'Music',
    'Download',
    'Downloads',
    'Música',
  ];

  // 🏆 GAMIFICACIÓN
  static const int xpPerMinuteListened = 10;
  static const int xpPerSongCompleted = 50;
  static const int xpPerAlbumCompleted = 500;
  static const int xpPerStreakDay = 100;

  // 📊 ESTADÍSTICAS
  static const int maxRecentTracksShown = 10;
  static const int maxTopGenresShown = 5;
  static const int daysForWeeklyStats = 7;
  static const int daysForMonthlyStats = 30;

  // ⏱️ DURACIÓN
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration notificationUpdateInterval = Duration(seconds: 1);

  // 🎨 UI
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // 🖼️ ALBUM COVER
  static const double albumCoverSmall = 56.0;
  static const double albumCoverMedium = 120.0;
  static const double albumCoverLarge = 280.0;

  // ⏯️ PLAYBACK
  static const double defaultPlaybackSpeed = 1.0;
  static const double minPlaybackSpeed = 0.5;
  static const double maxPlaybackSpeed = 2.0;
}
