import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tracks_table.dart';

part 'tracks_dao.g.dart';

/// DAO para gestionar tracks/canciones
@DriftAccessor(tables: [TracksTable])
class TracksDao extends DatabaseAccessor<AppDatabase> with _$TracksDaoMixin {
  TracksDao(AppDatabase db) : super(db);

  /// Obtener todos los tracks
  Future<List<TracksTableData>> getAllTracks() {
    return select(tracksTable).get();
  }

  /// Obtener track por ID
  Future<TracksTableData?> getTrackById(int id) {
    return (select(tracksTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Obtener track por filePath
  Future<TracksTableData?> getTrackByPath(String filePath) {
    return (select(tracksTable)..where((t) => t.filePath.equals(filePath)))
        .getSingleOrNull();
  }

  /// Buscar tracks por título, artista o álbum
  Future<List<TracksTableData>> searchTracks(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(tracksTable)
      ..where((t) =>
      t.title.lower().contains(lowerQuery) |
      t.artist.lower().contains(lowerQuery) |
      t.album.lower().contains(lowerQuery)))
        .get();
  }

  /// Obtener tracks favoritos
  Future<List<TracksTableData>> getFavoriteTracks() {
    return (select(tracksTable)..where((t) => t.isFavorite.equals(true)))
        .get();
  }

  /// Obtener tracks por artista
  Future<List<TracksTableData>> getTracksByArtist(String artist) {
    return (select(tracksTable)..where((t) => t.artist.equals(artist))).get();
  }

  /// Obtener tracks por álbum
  Future<List<TracksTableData>> getTracksByAlbum(String album) {
    return (select(tracksTable)..where((t) => t.album.equals(album))).get();
  }

  /// Obtener tracks por género
  Future<List<TracksTableData>> getTracksByGenre(String genre) {
    return (select(tracksTable)..where((t) => t.genre.equals(genre))).get();
  }

  /// Obtener tracks más reproducidos
  Future<List<TracksTableData>> getMostPlayedTracks({int limit = 10}) {
    return (select(tracksTable)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
        .get();
  }

  /// Obtener tracks recientes
  Future<List<TracksTableData>> getRecentTracks({int limit = 10}) {
    return (select(tracksTable)
      ..where((t) => t.lastPlayedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
      ..limit(limit))
        .get();
  }

  /// Insertar un track
  Future<int> insertTrack(TracksTableCompanion track) {
    return into(tracksTable).insert(track);
  }

  /// Insertar múltiples tracks
  Future<void> insertTracks(List<TracksTableCompanion> tracks) async {
    await batch((batch) {
      batch.insertAll(tracksTable, tracks);
    });
  }

  /// Actualizar un track
  Future<bool> updateTrack(TracksTableData track) {
    return update(tracksTable).replace(track);
  }

  /// Incrementar play count
  Future<void> incrementPlayCount(int trackId) async {
    final track = await getTrackById(trackId);
    if (track != null) {
      await (update(tracksTable)..where((t) => t.id.equals(trackId))).write(
        TracksTableCompanion(
          playCount: Value(track.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Incrementar skip count
  Future<void> incrementSkipCount(int trackId) async {
    final track = await getTrackById(trackId);
    if (track != null) {
      await (update(tracksTable)..where((t) => t.id.equals(trackId))).write(
        TracksTableCompanion(
          skipCount: Value(track.skipCount + 1),
        ),
      );
    }
  }

  /// Toggle favorito
  Future<void> toggleFavorite(int trackId) async {
    final track = await getTrackById(trackId);
    if (track != null) {
      await (update(tracksTable)..where((t) => t.id.equals(trackId))).write(
        TracksTableCompanion(
          isFavorite: Value(!track.isFavorite),
        ),
      );
    }
  }

  /// Eliminar un track
  Future<int> deleteTrack(int trackId) {
    return (delete(tracksTable)..where((t) => t.id.equals(trackId))).go();
  }

  /// Eliminar todos los tracks
  Future<int> deleteAllTracks() {
    return delete(tracksTable).go();
  }

  /// Obtener todos los artistas únicos
  Future<List<String>> getAllArtists() async {
    final query = selectOnly(tracksTable, distinct: true)
      ..addColumns([tracksTable.artist])
      ..orderBy([OrderingTerm.asc(tracksTable.artist)]);
    final results = await query.get();
    return results.map((row) => row.read(tracksTable.artist)!).toList();
  }

  /// Obtener todos los álbumes únicos
  Future<List<String>> getAllAlbums() async {
    final query = selectOnly(tracksTable, distinct: true)
      ..addColumns([tracksTable.album])
      ..orderBy([OrderingTerm.asc(tracksTable.album)]);
    final results = await query.get();
    return results.map((row) => row.read(tracksTable.album)!).toList();
  }

  /// Obtener todos los géneros únicos
  Future<List<String>> getAllGenres() async {
    final query = selectOnly(tracksTable, distinct: true)
      ..addColumns([tracksTable.genre])
      ..orderBy([OrderingTerm.asc(tracksTable.genre)]);
    final results = await query.get();
    return results.map((row) => row.read(tracksTable.genre)!).toList();
  }

  /// Contar total de tracks
  Future<int> countTracks() async {
    final count = tracksTable.id.count();
    final query = selectOnly(tracksTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Observar cambios en todos los tracks (Stream)
  Stream<List<TracksTableData>> watchAllTracks() {
    return select(tracksTable).watch();
  }

  /// Observar tracks favoritos (Stream)
  Stream<List<TracksTableData>> watchFavoriteTracks() {
    return (select(tracksTable)..where((t) => t.isFavorite.equals(true)))
        .watch();
  }

  /// Insertar solo si no existe (evitar duplicados)
  Future<int> insertTrackIfNotExists(TracksTableCompanion track) async {
    final path = track.filePath.value;
    final existing = await getTrackByPath(path);

    if (existing != null) {
      print('⚠️ Track ya existe: ${existing.title}');
      return existing.id!;
    }

    return await insertTrack(track);
  }
}
