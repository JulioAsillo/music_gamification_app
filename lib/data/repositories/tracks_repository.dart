import '../database/app_database.dart';
import '../database/daos/tracks_dao.dart';
import '../models/track.dart';
import 'package:drift/drift.dart';

/// Repositorio para gestionar tracks
class TracksRepository {
  final TracksDao _tracksDao;

  TracksRepository(AppDatabase database) : _tracksDao = TracksDao(database);

  /// Obtener todos los tracks
  Future<List<Track>> getAllTracks() async {
    final data = await _tracksDao.getAllTracks();
    return data.map(_mapToTrack).toList();
  }

  /// Obtener track por ID
  Future<Track?> getTrackById(int id) async {
    final data = await _tracksDao.getTrackById(id);
    return data != null ? _mapToTrack(data) : null;
  }

  /// Buscar tracks
  Future<List<Track>> searchTracks(String query) async {
    final data = await _tracksDao.searchTracks(query);
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks favoritos
  Future<List<Track>> getFavoriteTracks() async {
    final data = await _tracksDao.getFavoriteTracks();
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks por artista
  Future<List<Track>> getTracksByArtist(String artist) async {
    final data = await _tracksDao.getTracksByArtist(artist);
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks por álbum
  Future<List<Track>> getTracksByAlbum(String album) async {
    final data = await _tracksDao.getTracksByAlbum(album);
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks por género
  Future<List<Track>> getTracksByGenre(String genre) async {
    final data = await _tracksDao.getTracksByGenre(genre);
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks más reproducidos
  Future<List<Track>> getMostPlayedTracks({int limit = 10}) async {
    final data = await _tracksDao.getMostPlayedTracks(limit: limit);
    return data.map(_mapToTrack).toList();
  }

  /// Obtener tracks recientes
  Future<List<Track>> getRecentTracks({int limit = 10}) async {
    final data = await _tracksDao.getRecentTracks(limit: limit);
    return data.map(_mapToTrack).toList();
  }

  /// Agregar un track
  Future<int> addTrack(Track track) async {
    return await _tracksDao.insertTrack(_mapToCompanion(track));
  }

  /// Agregar múltiples tracks
  Future<void> addTracks(List<Track> tracks) async {
    final companions = tracks.map(_mapToCompanion).toList();
    await _tracksDao.insertTracks(companions);
  }

  /// Actualizar un track
  Future<bool> updateTrack(Track track) async {
    return await _tracksDao.updateTrack(_mapToTableData(track));
  }

  /// Incrementar contador de reproducción
  Future<void> incrementPlayCount(int trackId) async {
    await _tracksDao.incrementPlayCount(trackId);
  }

  /// Incrementar contador de skip
  Future<void> incrementSkipCount(int trackId) async {
    await _tracksDao.incrementSkipCount(trackId);
  }

  /// Toggle favorito
  Future<void> toggleFavorite(int trackId) async {
    await _tracksDao.toggleFavorite(trackId);
  }

  /// Eliminar un track
  Future<int> deleteTrack(int trackId) async {
    return await _tracksDao.deleteTrack(trackId);
  }

  /// Obtener todos los artistas
  Future<List<String>> getAllArtists() async {
    return await _tracksDao.getAllArtists();
  }

  /// Obtener todos los álbumes
  Future<List<String>> getAllAlbums() async {
    return await _tracksDao.getAllAlbums();
  }

  /// Obtener todos los géneros
  Future<List<String>> getAllGenres() async {
    return await _tracksDao.getAllGenres();
  }

  /// Contar total de tracks
  Future<int> getTracksCount() async {
    return await _tracksDao.countTracks();
  }

  /// Observar todos los tracks (Stream)
  Stream<List<Track>> watchAllTracks() {
    return _tracksDao.watchAllTracks().map(
          (data) => data.map(_mapToTrack).toList(),
    );
  }

  /// Observar tracks favoritos (Stream)
  Stream<List<Track>> watchFavoriteTracks() {
    return _tracksDao.watchFavoriteTracks().map(
          (data) => data.map(_mapToTrack).toList(),
    );
  }

  // ====== MAPPERS ======

  Track _mapToTrack(TracksTableData data) {
    return Track(
      id: data.id,
      filePath: data.filePath,
      title: data.title,
      artist: data.artist,
      album: data.album,
      genre: data.genre,
      durationMs: data.durationMs,
      addedAt: data.addedAt,
      playCount: data.playCount,
      skipCount: data.skipCount,
      lastPlayedAt: data.lastPlayedAt,
      isFavorite: data.isFavorite,
      coverArtPath: data.coverArtPath,
    );
  }

  TracksTableCompanion _mapToCompanion(Track track) {
    return TracksTableCompanion(
      id: track.id != null ? Value(track.id!) : const Value.absent(),
      filePath: Value(track.filePath),
      title: Value(track.title),
      artist: Value(track.artist),
      album: Value(track.album),
      genre: Value(track.genre),
      durationMs: Value(track.durationMs),
      addedAt: Value(track.addedAt),
      playCount: Value(track.playCount),
      skipCount: Value(track.skipCount),
      lastPlayedAt: Value(track.lastPlayedAt),
      isFavorite: Value(track.isFavorite),
      coverArtPath: Value(track.coverArtPath),
    );
  }

  TracksTableData _mapToTableData(Track track) {
    return TracksTableData(
      id: track.id!,
      filePath: track.filePath,
      title: track.title,
      artist: track.artist,
      album: track.album,
      genre: track.genre,
      durationMs: track.durationMs,
      addedAt: track.addedAt,
      playCount: track.playCount,
      skipCount: track.skipCount,
      lastPlayedAt: track.lastPlayedAt,
      isFavorite: track.isFavorite,
      coverArtPath: track.coverArtPath,
    );
  }
}
