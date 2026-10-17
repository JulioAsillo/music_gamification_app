import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/playlists_table.dart';
import '../tables/tracks_table.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';

part 'playlists_dao.g.dart';

/// DAO para gestionar playlists
@DriftAccessor(tables: [PlaylistsTable, PlaylistTracksTable, TracksTable])
class PlaylistsDao extends DatabaseAccessor<AppDatabase> with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  /// Obtener todas las playlists
  Future<List<Playlist>> getAllPlaylists() async {
    final query = select(playlistsTable)..orderBy([
      (t) => OrderingTerm(expression: t.isFavorite, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    final playlists = await query.get();

    // Obtener conteo de tracks y portada para cada playlist
    final result = <Playlist>[];
    for (final playlist in playlists) {
      final count = await _getTrackCount(playlist.id);
      final autoCover = await _getFirstTrackCoverWithImage(playlist.id);

      // Si la playlist no tiene portada propia, usar la del primer track CON portada
      final coverPath = playlist.coverPath ?? autoCover;

      result.add(Playlist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        coverPath: coverPath,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
        isFavorite: playlist.isFavorite,
        trackCount: count,
      ));
    }

    return result;
  }

  /// Obtener una playlist por ID
  Future<Playlist?> getPlaylistById(int id) async {
    final playlist = await (select(playlistsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (playlist == null) return null;

    final count = await _getTrackCount(id);
    final autoCover = await _getFirstTrackCoverWithImage(id);

    // Si la playlist no tiene portada propia, usar la del primer track CON portada
    final coverPath = playlist.coverPath ?? autoCover;

    return Playlist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      coverPath: coverPath,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      isFavorite: playlist.isFavorite,
      trackCount: count,
    );
  }

  /// Crear nueva playlist
  Future<int> createPlaylist({
    required String name,
    String? description,
    String? coverPath,
  }) async {
    return await into(playlistsTable).insert(
      PlaylistsTableCompanion.insert(
        name: name,
        description: Value(description),
        coverPath: Value(coverPath),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Actualizar playlist
  Future<bool> updatePlaylist({
    required int id,
    String? name,
    String? description,
    String? coverPath,
    bool? isFavorite,
  }) async {
    final result = await (update(playlistsTable)..where((t) => t.id.equals(id))).write(
      PlaylistsTableCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: Value(description),
        coverPath: Value(coverPath),
        isFavorite: isFavorite != null ? Value(isFavorite) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return result > 0;
  }

  /// Eliminar playlist
  Future<int> deletePlaylist(int id) async {
    return await (delete(playlistsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Agregar track a playlist
  Future<int> addTrackToPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    // Obtener la posición más alta actual
    final maxPosition = await _getMaxPosition(playlistId);

    try {
      final id = await into(playlistTracksTable).insert(
        PlaylistTracksTableCompanion.insert(
          playlistId: playlistId,
          trackId: trackId,
          position: maxPosition + 1,
          addedAt: DateTime.now(),
        ),
      );

      // Actualizar fecha de modificación de la playlist
      await _updatePlaylistTimestamp(playlistId);

      return id;
    } catch (e) {
      // Si el track ya existe, retornar 0
      return 0;
    }
  }

  /// Eliminar track de playlist
  Future<bool> removeTrackFromPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    final result = await (delete(playlistTracksTable)
      ..where((t) => t.playlistId.equals(playlistId) & t.trackId.equals(trackId))).go();

    if (result > 0) {
      // Reordenar las posiciones
      await _reorderPositions(playlistId);
      await _updatePlaylistTimestamp(playlistId);
    }

    return result > 0;
  }

  /// Obtener tracks de una playlist
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final query = select(playlistTracksTable).join([
      innerJoin(tracksTable, tracksTable.id.equalsExp(playlistTracksTable.trackId)),
    ])
      ..where(playlistTracksTable.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm(expression: playlistTracksTable.position)]);

    final results = await query.get();

    return results.map((row) {
      final trackData = row.readTable(tracksTable);
      return Track.fromDatabase(trackData);
    }).toList();
  }

  /// Reordenar track en playlist
  Future<void> reorderTrack({
    required int playlistId,
    required int trackId,
    required int newPosition,
  }) async {
    await (update(playlistTracksTable)
      ..where((t) => t.playlistId.equals(playlistId) & t.trackId.equals(trackId)))
        .write(PlaylistTracksTableCompanion(position: Value(newPosition)));

    await _reorderPositions(playlistId);
    await _updatePlaylistTimestamp(playlistId);
  }

  /// Toggle favorito
  Future<void> toggleFavorite(int playlistId) async {
    final playlist = await (select(playlistsTable)..where((t) => t.id.equals(playlistId))).getSingle();

    await (update(playlistsTable)..where((t) => t.id.equals(playlistId))).write(
      PlaylistsTableCompanion(
        isFavorite: Value(!playlist.isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Watch todas las playlists (reactive)
  Stream<List<Playlist>> watchAllPlaylists() async* {
    // Crear un stream que emita cuando cambie cualquiera de las dos tablas
    await for (final _ in select(playlistsTable).watch()) {
      // También forzar actualización cuando cambien los tracks
      final _ = select(playlistTracksTable).watch().first;

      final playlists = await (select(playlistsTable)..orderBy([
        (t) => OrderingTerm(expression: t.isFavorite, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ])).get();

      final result = <Playlist>[];
      for (final playlist in playlists) {
        final count = await _getTrackCount(playlist.id);
        final autoCover = await _getFirstTrackCoverWithImage(playlist.id);

        // Si la playlist no tiene portada propia, usar la del primer track CON portada
        final coverPath = playlist.coverPath ?? autoCover;

        result.add(Playlist(
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          coverPath: coverPath,
          createdAt: playlist.createdAt,
          updatedAt: playlist.updatedAt,
          isFavorite: playlist.isFavorite,
          trackCount: count,
        ));
      }

      yield result;

      // Escuchar cambios en tracks y re-emitir
      await for (final _ in select(playlistTracksTable).watch()) {
        final updatedResult = <Playlist>[];
        for (final playlist in playlists) {
          final count = await _getTrackCount(playlist.id);
          final autoCover = await _getFirstTrackCoverWithImage(playlist.id);
          final coverPath = playlist.coverPath ?? autoCover;

          updatedResult.add(Playlist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            coverPath: coverPath,
            createdAt: playlist.createdAt,
            updatedAt: playlist.updatedAt,
            isFavorite: playlist.isFavorite,
            trackCount: count,
          ));
        }
        yield updatedResult;
      }
    }
  }

  /// Watch una playlist específica
  Stream<Playlist?> watchPlaylist(int id) {
    return (select(playlistsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((playlist) async {
      if (playlist == null) return null;

      final count = await _getTrackCount(id);
      final autoCover = await _getFirstTrackCoverWithImage(id);

      // Si la playlist no tiene portada propia, usar la del primer track CON portada
      final coverPath = playlist.coverPath ?? autoCover;

      return Playlist(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        coverPath: coverPath,
        createdAt: playlist.createdAt,
        updatedAt: playlist.updatedAt,
        isFavorite: playlist.isFavorite,
        trackCount: count,
      );
    });
  }

  /// Watch tracks de una playlist
  Stream<List<Track>> watchPlaylistTracks(int playlistId) {
    final query = select(playlistTracksTable).join([
      innerJoin(tracksTable, tracksTable.id.equalsExp(playlistTracksTable.trackId)),
    ])
      ..where(playlistTracksTable.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm(expression: playlistTracksTable.position)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final trackData = row.readTable(tracksTable);
        return Track.fromDatabase(trackData);
      }).toList();
    });
  }

  // Métodos privados auxiliares

  Future<int> _getTrackCount(int playlistId) async {
    final countQuery = selectOnly(playlistTracksTable)
      ..addColumns([playlistTracksTable.id.count()])
      ..where(playlistTracksTable.playlistId.equals(playlistId));

    final result = await countQuery.getSingle();
    return result.read(playlistTracksTable.id.count()) ?? 0;
  }

  /// Obtener la portada del primer track que SÍ tenga imagen
  Future<String?> _getFirstTrackCoverWithImage(int playlistId) async {
    final query = select(playlistTracksTable).join([
      innerJoin(tracksTable, tracksTable.id.equalsExp(playlistTracksTable.trackId)),
    ])
      ..where(playlistTracksTable.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm(expression: playlistTracksTable.position)]);

    final results = await query.get();

    // Buscar el primer track que tenga portada
    for (final row in results) {
      final trackData = row.readTable(tracksTable);
      if (trackData.coverArtPath != null && trackData.coverArtPath!.isNotEmpty) {
        return trackData.coverArtPath;
      }
    }

    return null;
  }

  Future<int> _getMaxPosition(int playlistId) async {
    final maxQuery = selectOnly(playlistTracksTable)
      ..addColumns([playlistTracksTable.position.max()])
      ..where(playlistTracksTable.playlistId.equals(playlistId));

    final result = await maxQuery.getSingleOrNull();
    return result?.read(playlistTracksTable.position.max()) ?? 0;
  }

  Future<void> _reorderPositions(int playlistId) async {
    final tracks = await (select(playlistTracksTable)
      ..where((t) => t.playlistId.equals(playlistId))
      ..orderBy([(t) => OrderingTerm(expression: t.position)])).get();

    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].position != i + 1) {
        await (update(playlistTracksTable)..where((t) => t.id.equals(tracks[i].id)))
            .write(PlaylistTracksTableCompanion(position: Value(i + 1)));
      }
    }
  }

  Future<void> _updatePlaylistTimestamp(int playlistId) async {
    await (update(playlistsTable)..where((t) => t.id.equals(playlistId)))
        .write(PlaylistsTableCompanion(updatedAt: Value(DateTime.now())));
  }
}

