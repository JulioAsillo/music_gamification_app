import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/playlist.dart';
import '../../data/models/track.dart';
import '../../data/repositories/playlists_repository.dart';
import 'database_provider.dart';

/// Provider del repositorio de playlists
final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PlaylistsRepository(database);
});

/// Provider para todas las playlists
final allPlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  final repository = ref.watch(playlistsRepositoryProvider);
  return repository.watchAllPlaylists();
});

/// Provider para una playlist específica
final playlistProvider = StreamProvider.family<Playlist?, int>((ref, id) {
  final repository = ref.watch(playlistsRepositoryProvider);
  return repository.watchPlaylist(id);
});

/// Provider para tracks de una playlist
final playlistTracksProvider = StreamProvider.family<List<Track>, int>((ref, playlistId) {
  final repository = ref.watch(playlistsRepositoryProvider);
  return repository.watchPlaylistTracks(playlistId);
});

/// Notifier para gestionar playlists
class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  final PlaylistsRepository _repository;

  PlaylistsNotifier(this._repository) : super([]) {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _repository.getAllPlaylists();
      state = playlists;
    } catch (e, st) {
      print('❌ Error cargando playlists: $e');
      state = [];
    }
  }

  /// Crear nueva playlist
  Future<int?> createPlaylist({
    required String name,
    String? description,
    String? coverPath,
  }) async {
    try {
      final id = await _repository.createPlaylist(
        name: name,
        description: description,
        coverPath: coverPath,
      );
      await _loadPlaylists();
      return id;
    } catch (e) {
      print('❌ Error creando playlist: $e');
      return null;
    }
  }

  /// Actualizar playlist
  Future<bool> updatePlaylist({
    required int id,
    String? name,
    String? description,
    String? coverPath,
    bool? isFavorite,
  }) async {
    try {
      final result = await _repository.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverPath: coverPath,
        isFavorite: isFavorite,
      );
      if (result) {
        await _loadPlaylists();
      }
      return result;
    } catch (e) {
      print('❌ Error actualizando playlist: $e');
      return false;
    }
  }

  /// Eliminar playlist
  Future<bool> deletePlaylist(int id) async {
    try {
      final result = await _repository.deletePlaylist(id);
      if (result) {
        await _loadPlaylists();
      }
      return result;
    } catch (e) {
      print('❌ Error eliminando playlist: $e');
      return false;
    }
  }

  /// Agregar track a playlist
  Future<bool> addTrackToPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      return await _repository.addTrackToPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
    } catch (e) {
      print('❌ Error agregando track a playlist: $e');
      return false;
    }
  }

  /// Eliminar track de playlist
  Future<bool> removeTrackFromPlaylist({
    required int playlistId,
    required int trackId,
  }) async {
    try {
      return await _repository.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
      );
    } catch (e) {
      print('❌ Error eliminando track de playlist: $e');
      return false;
    }
  }

  /// Toggle favorito
  Future<void> toggleFavorite(int playlistId) async {
    try {
      await _repository.toggleFavorite(playlistId);
      await _loadPlaylists();
    } catch (e) {
      print('❌ Error toggling favorito: $e');
    }
  }
}

/// Provider del notifier de playlists
final playlistsNotifierProvider = StateNotifierProvider<PlaylistsNotifier, List<Playlist>>((ref) {
  final repository = ref.watch(playlistsRepositoryProvider);
  return PlaylistsNotifier(repository);
});

