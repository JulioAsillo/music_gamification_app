import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/track.dart';
import 'repositories_provider.dart';

part 'tracks_provider.g.dart';

/// Provider para obtener todos los tracks
@riverpod
Future<List<Track>> allTracks(AllTracksRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getAllTracks();
}

/// Provider para obtener tracks favoritos
@riverpod
Future<List<Track>> favoriteTracks(FavoriteTracksRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getFavoriteTracks();
}

/// Provider para obtener tracks más reproducidos
@riverpod
Future<List<Track>> mostPlayedTracks(MostPlayedTracksRef ref, {int limit = 10}) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getMostPlayedTracks(limit: limit);
}

/// Provider para obtener tracks recientes
@riverpod
Future<List<Track>> recentTracks(RecentTracksRef ref, {int limit = 10}) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getRecentTracks(limit: limit);
}

/// Provider para buscar tracks
@riverpod
Future<List<Track>> searchTracks(SearchTracksRef ref, String query) async {
  final repository = ref.watch(tracksRepositoryProvider);
  if (query.isEmpty) return [];
  return await repository.searchTracks(query);
}

/// Provider para obtener tracks por artista
@riverpod
Future<List<Track>> tracksByArtist(TracksByArtistRef ref, String artist) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getTracksByArtist(artist);
}

/// Provider para obtener tracks por álbum
@riverpod
Future<List<Track>> tracksByAlbum(TracksByAlbumRef ref, String album) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getTracksByAlbum(album);
}

/// Provider para obtener tracks por género
@riverpod
Future<List<Track>> tracksByGenre(TracksByGenreRef ref, String genre) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getTracksByGenre(genre);
}

/// Provider para obtener un track específico por ID
@riverpod
Future<Track?> trackById(TrackByIdRef ref, int id) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getTrackById(id);
}

/// Provider para obtener todos los artistas
@riverpod
Future<List<String>> allArtists(AllArtistsRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getAllArtists();
}

/// Provider para obtener todos los álbumes
@riverpod
Future<List<String>> allAlbums(AllAlbumsRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getAllAlbums();
}

/// Provider para obtener todos los géneros
@riverpod
Future<List<String>> allGenres(AllGenresRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getAllGenres();
}

/// Provider para contar tracks
@riverpod
Future<int> tracksCount(TracksCountRef ref) async {
  final repository = ref.watch(tracksRepositoryProvider);
  return await repository.getTracksCount();
}

/// Stream provider para observar todos los tracks
@riverpod
Stream<List<Track>> watchAllTracks(WatchAllTracksRef ref) {
  final repository = ref.watch(tracksRepositoryProvider);
  return repository.watchAllTracks();
}

/// Stream provider para observar tracks favoritos
@riverpod
Stream<List<Track>> watchFavoriteTracks(WatchFavoriteTracksRef ref) {
  final repository = ref.watch(tracksRepositoryProvider);
  return repository.watchFavoriteTracks();
}
