import '../database/app_database.dart';
import '../models/playlist.dart';
import '../models/track.dart';

/// Repositorio para gestionar playlists
class PlaylistsRepository {
  final AppDatabase _database;

  PlaylistsRepository(this._database);

  /// Obtener todas las playlists
  Future<List<Playlist>> getAllPlaylists() async {
    return await _database.playlistsDao.getAllPlaylists();
  }

  /// Obtener playlist por ID
  Future<Playlist?> getPlaylistById(int id) async {
    return await _database.playlistsDao.getPlaylistById(id);
  }

  /// Crear nueva playlist
  Future<int> createPlaylist({
    required String name,
    String? description,
    String? coverPath,
  }) async {
    return await _database.playlistsDao.createPlaylist(
      name: name,
      description: description,
      coverPath: coverPath,
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
    return await _database.playlistsDao.updatePlaylist(
      id: id,
      name: name,
      description: description,
      coverPath: coverPath,
      isFavorite: isFavorite,
    );
  }

  /// Eliminar playlist
  Future<bool> deletePlaylist(int id) async {
    final result = await _database.playlistsDao.deletePlaylist(id);
    return result > 0;
  }

  /// Agregar track a playlist
  Future<bool> addTrackToPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    final result = await _database.playlistsDao.addTrackToPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
    return result > 0;
  }

  /// Eliminar track de playlist
  Future<bool> removeTrackFromPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    return await _database.playlistsDao.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
  }

  /// Obtener tracks de playlist
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    return await _database.playlistsDao.getPlaylistTracks(playlistId);
  }

  /// Reordenar track
  Future<void> reorderTrack({
    required int playlistId,
    required int trackId,
    required int newPosition,
  }) async {
    await _database.playlistsDao.reorderTrack(
      playlistId: playlistId,
      trackId: trackId,
      newPosition: newPosition,
    );
  }

  /// Toggle favorito
  Future<void> toggleFavorite(int playlistId) async {
    await _database.playlistsDao.toggleFavorite(playlistId);
  }

  /// Watch todas las playlists
  Stream<List<Playlist>> watchAllPlaylists() {
    return _database.playlistsDao.watchAllPlaylists();
  }

  /// Watch playlist específica
  Stream<Playlist?> watchPlaylist(int id) {
    return _database.playlistsDao.watchPlaylist(id);
  }

  /// Watch tracks de playlist
  Stream<List<Track>> watchPlaylistTracks(int playlistId) {
    return _database.playlistsDao.watchPlaylistTracks(playlistId);
  }
}

