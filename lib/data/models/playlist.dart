import '../database/app_database.dart';

/// Modelo de Playlist con sus tracks
class Playlist {
  final int? id;
  final String name;
  final String? description;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int trackCount;

  Playlist({
    this.id,
    required this.name,
    this.description,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.trackCount = 0,
  });

  /// Crear desde un registro de la base de datos
  factory Playlist.fromDatabase(PlaylistsTableData data, {int trackCount = 0}) {
    return Playlist(
      id: data.id,
      name: data.name,
      description: data.description,
      coverPath: data.coverPath,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      isFavorite: data.isFavorite,
      trackCount: trackCount,
    );
  }

  /// Copiar con nuevos valores
  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    String? coverPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, trackCount: $trackCount)';
  }
}

/// Modelo para track en playlist con su posición
class PlaylistTrack {
  final int id;
  final int playlistId;
  final int trackId;
  final int position;
  final DateTime addedAt;

  PlaylistTrack({
    required this.id,
    required this.playlistId,
    required this.trackId,
    required this.position,
    required this.addedAt,
  });

  /// Crear desde un registro de la base de datos
  factory PlaylistTrack.fromDatabase(PlaylistTracksTableData data) {
    return PlaylistTrack(
      id: data.id,
      playlistId: data.playlistId,
      trackId: data.trackId,
      position: data.position,
      addedAt: data.addedAt,
    );
  }
}

