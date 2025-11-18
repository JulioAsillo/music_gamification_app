import 'package:equatable/equatable.dart';

/// Modelo de una canción/track
class Track extends Equatable {
  final int? id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int durationMs;
  final DateTime addedAt;
  final int playCount;
  final int skipCount;
  final DateTime? lastPlayedAt;
  final bool isFavorite;
  final String? coverArtPath;

  const Track({
    this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.durationMs,
    required this.addedAt,
    this.playCount = 0,
    this.skipCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
    this.coverArtPath,
  });

  /// Constructor para crear un track vacío
  factory Track.empty() {
    return Track(
      filePath: '',
      title: 'Unknown',
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      genre: 'Unknown',
      durationMs: 0,
      addedAt: DateTime.now(),
    );
  }

  /// Copia con modificaciones
  Track copyWith({
    int? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? durationMs,
    DateTime? addedAt,
    int? playCount,
    int? skipCount,
    DateTime? lastPlayedAt,
    bool? isFavorite,
    String? coverArtPath,
  }) {
    return Track(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      coverArtPath: coverArtPath ?? this.coverArtPath,
    );
  }

  /// Convertir a Map (para BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'durationMs': durationMs,
      'addedAt': addedAt.toIso8601String(),
      'playCount': playCount,
      'skipCount': skipCount,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'coverArtPath': coverArtPath,
    };
  }

  /// Crear desde Map (desde BD)
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int?,
      filePath: map['filePath'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      genre: map['genre'] as String,
      durationMs: map['durationMs'] as int,
      addedAt: DateTime.parse(map['addedAt'] as String),
      playCount: map['playCount'] as int? ?? 0,
      skipCount: map['skipCount'] as int? ?? 0,
      lastPlayedAt: map['lastPlayedAt'] != null
          ? DateTime.parse(map['lastPlayedAt'] as String)
          : null,
      isFavorite: (map['isFavorite'] as int?) == 1,
      coverArtPath: map['coverArtPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    filePath,
    title,
    artist,
    album,
    genre,
    durationMs,
    addedAt,
    playCount,
    skipCount,
    lastPlayedAt,
    isFavorite,
    coverArtPath,
  ];

  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artist, album: $album)';
  }
}
