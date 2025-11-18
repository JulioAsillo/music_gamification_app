/// Origen de reproducción de una canción
enum PlaybackSource {
  /// Reproducción manual por el usuario
  manual,

  /// Desde shuffle aleatorio
  shuffle,

  /// Desde una playlist
  playlist,

  /// Desde una sesión guardada (gym/estudio)
  session,

  /// Desde un álbum
  album,

  /// Desde un artista
  artist,

  /// Desde búsqueda
  search,
}

extension PlaybackSourceExtension on PlaybackSource {
  String get displayName {
    switch (this) {
      case PlaybackSource.manual:
        return 'Manual';
      case PlaybackSource.shuffle:
        return 'Aleatorio';
      case PlaybackSource.playlist:
        return 'Playlist';
      case PlaybackSource.session:
        return 'Sesión';
      case PlaybackSource.album:
        return 'Álbum';
      case PlaybackSource.artist:
        return 'Artista';
      case PlaybackSource.search:
        return 'Búsqueda';
    }
  }
}
