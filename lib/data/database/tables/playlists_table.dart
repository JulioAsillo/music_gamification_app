import 'package:drift/drift.dart';

/// Tabla de playlists personalizadas
class PlaylistsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable().withLength(max: 500)();
  TextColumn get coverPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  String get tableName => 'playlists';
}

/// Tabla de relación entre playlists y tracks
class PlaylistTracksTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(PlaylistsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId => integer()();
  IntColumn get position => integer()(); // Orden en la playlist
  DateTimeColumn get addedAt => dateTime()();

  @override
  String get tableName => 'playlist_tracks';

  @override
  List<Set<Column>> get uniqueKeys => [
    {playlistId, trackId}, // No permitir tracks duplicados en la misma playlist
  ];
}

