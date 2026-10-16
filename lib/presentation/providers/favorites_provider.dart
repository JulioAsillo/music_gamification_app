import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories_provider.dart';
import 'tracks_provider.dart';

/// Provider para toggle de favoritos
final toggleFavoriteProvider = FutureProvider.family<void, int>((ref, trackId) async {
  final repository = ref.watch(tracksRepositoryProvider);
  await repository.toggleFavorite(trackId);

  // Invalidar los providers de tracks para refrescar la UI
  ref.invalidate(watchAllTracksProvider);
  ref.invalidate(watchFavoriteTracksProvider);
});

/// Notificador para gestión de favoritos
class FavoritesNotifier extends StateNotifier<Set<int>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super({});

  /// Toggle de favorito
  Future<void> toggleFavorite(int trackId) async {
    final repository = _ref.read(tracksRepositoryProvider);
    await repository.toggleFavorite(trackId);

    // Actualizar el estado local
    if (state.contains(trackId)) {
      state = {...state}..remove(trackId);
    } else {
      state = {...state, trackId};
    }

    // Invalidar providers relacionados
    _ref.invalidate(watchAllTracksProvider);
    _ref.invalidate(watchFavoriteTracksProvider);
  }

  /// Verificar si un track es favorito
  bool isFavorite(int trackId) {
    return state.contains(trackId);
  }
}

/// Provider del notificador de favoritos
final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  return FavoritesNotifier(ref);
});

