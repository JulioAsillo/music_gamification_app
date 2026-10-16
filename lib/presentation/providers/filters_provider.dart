import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/track.dart';
import 'tracks_provider.dart';
import 'repositories_provider.dart';
import '../screens/library/filters_screen.dart';

/// Provider para tracks filtrados y ordenados
final filteredAndSortedTracksProvider = FutureProvider<List<Track>>((ref) async {
  // Obtener todos los tracks
  final allTracks = await ref.watch(allTracksProvider.future);

  // Obtener filtros activos
  final filters = ref.watch(currentFilterProvider);

  // Obtener tipo de ordenamiento
  final sortType = ref.watch(sortTypeProvider);

  // Aplicar filtros
  var filteredTracks = allTracks;

  final genres = filters[FilterType.genre] ?? [];
  if (genres.isNotEmpty) {
    filteredTracks = filteredTracks.where((t) => genres.contains(t.genre)).toList();
  }

  final artists = filters[FilterType.artist] ?? [];
  if (artists.isNotEmpty) {
    filteredTracks = filteredTracks.where((t) => artists.contains(t.artist)).toList();
  }

  final albums = filters[FilterType.album] ?? [];
  if (albums.isNotEmpty) {
    filteredTracks = filteredTracks.where((t) => albums.contains(t.album)).toList();
  }

  // Aplicar ordenamiento
  switch (sortType) {
    case SortType.nameAsc:
      filteredTracks.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortType.nameDesc:
      filteredTracks.sort((a, b) => b.title.compareTo(a.title));
      break;
    case SortType.dateAdded:
      filteredTracks.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      break;
    case SortType.mostPlayed:
      filteredTracks.sort((a, b) => b.playCount.compareTo(a.playCount));
      break;
    case SortType.duration:
      filteredTracks.sort((a, b) => b.durationMs.compareTo(a.durationMs));
      break;
  }

  return filteredTracks;
});


/// Provider para tracks filtrados y ordenados (con watch)
final watchFilteredAndSortedTracksProvider = StreamProvider.autoDispose<List<Track>>((ref) async* {
  // Mantener el provider vivo para evitar recargas
  ref.keepAlive();

  // Escuchar cambios en los filtros y ordenamiento
  final filters = ref.watch(currentFilterProvider);
  final sortType = ref.watch(sortTypeProvider);

  // Escuchar el stream de todos los tracks
  await for (final tracks in ref.watch(watchAllTracksProvider.future).asStream().asyncExpand(
    (initialTracks) async* {
      yield initialTracks;
      // Seguir escuchando cambios
      await for (final newTracks in ref.watch(tracksRepositoryProvider).watchAllTracks()) {
        yield newTracks;
      }
    },
  )) {
    var filteredTracks = List<Track>.from(tracks);

    // Aplicar filtros
    final genres = filters[FilterType.genre] ?? [];
    if (genres.isNotEmpty) {
      filteredTracks = filteredTracks.where((t) => genres.contains(t.genre)).toList();
    }

    final artists = filters[FilterType.artist] ?? [];
    if (artists.isNotEmpty) {
      filteredTracks = filteredTracks.where((t) => artists.contains(t.artist)).toList();
    }

    final albums = filters[FilterType.album] ?? [];
    if (albums.isNotEmpty) {
      filteredTracks = filteredTracks.where((t) => albums.contains(t.album)).toList();
    }

    // Aplicar ordenamiento
    switch (sortType) {
      case SortType.nameAsc:
        filteredTracks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.nameDesc:
        filteredTracks.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortType.dateAdded:
        filteredTracks.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SortType.mostPlayed:
        filteredTracks.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SortType.duration:
        filteredTracks.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
    }

    yield filteredTracks;
  }
});

/// Provider para indicar si hay filtros activos
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final filters = ref.watch(currentFilterProvider);
  return filters.values.any((list) => list.isNotEmpty);
});

/// Provider para el número de filtros activos
final activeFiltersCountProvider = Provider<int>((ref) {
  final filters = ref.watch(currentFilterProvider);
  return filters.values.fold(0, (sum, list) => sum + list.length);
});

