import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_gamification_app/presentation/screens/library/search_screen.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/track.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/filters_provider.dart';
import '../scan/scan_sheet.dart';
import 'favorites_screen.dart';
import 'filters_screen.dart';
import 'grouped_library_screen.dart';

/// Pantalla de biblioteca de música
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // Cache local para evitar parpadeos
  List<Track>? _cachedTracks;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final tracksAsync = ref.watch(watchFilteredAndSortedTracksProvider);
    final hasFilters = ref.watch(hasActiveFiltersProvider);
    final filtersCount = ref.watch(activeFiltersCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Biblioteca',
          style: AppTextStyles.heading2(context),
        ),
        actions: [
          // Botón de álbumes
          IconButton(
            icon: const Icon(Icons.album),
            tooltip: 'Ver por Álbumes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupedLibraryScreen(
                    groupingType: GroupingType.albums,
                  ),
                ),
              );
            },
          ),
          // Botón de artistas
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Ver por Artistas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupedLibraryScreen(
                    groupingType: GroupingType.artists,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favoritos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Badge(
              label: Text(filtersCount.toString()),
              isLabelVisible: hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FiltersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: tracksAsync.when(
        data: (tracks) {
          // Actualizar cache
          _cachedTracks = tracks;

          if (tracks.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildTracksList(tracks);
        },
        loading: () {
          // Mostrar cache mientras carga para evitar parpadeo
          if (_cachedTracks != null && _cachedTracks!.isNotEmpty) {
            return _buildTracksList(_cachedTracks!);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          // Mostrar cache en caso de error si existe
          if (_cachedTracks != null && _cachedTracks!.isNotEmpty) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error actualizando: ${error.toString().substring(0, 50)}...',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildTracksList(_cachedTracks!)),
              ],
            );
          }
          return Center(
            child: Text('Error: $error'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'library_scan_fab',
        onPressed: () => showScanSheet(context),
        child: const Icon(Icons.search),
        tooltip: 'Escanear música',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 80,
            color: AppColors.accentDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Biblioteca vacía',
            style: AppTextStyles.heading2(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón para escanear música',
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks) {
    return Consumer(
      builder: (context, ref, child) {
        final currentTrack = ref.watch(currentTrackProvider);
        final playerState = ref.watch(musicPlayerProvider.select((state) => (
          isLoading: state.isLoading,
          currentTrackId: state.currentTrack?.id,
        )));

        return ListView.builder(
          key: const PageStorageKey<String>('library_list'),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: tracks.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          cacheExtent: 1000, // Pre-cache items for better scroll performance
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isPlaying = currentTrack?.id == track.id;
            final isLoading = playerState.isLoading && playerState.currentTrackId == track.id;

            return _TrackListItem(
              key: ValueKey(track.id),
              track: track,
              isPlaying: isPlaying,
              isLoading: isLoading,
              onTap: () {
                ref.read(musicPlayerProvider.notifier).playTracks(
                  tracks,
                  initialIndex: index,
                );
              },
              onMorePressed: () {
                _showTrackOptions(context, ref, track);
              },
            );
          },
        );
      },
    );
  }

  /// Mostrar opciones del track
  void _showTrackOptions(BuildContext context, WidgetRef ref, Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Reproducir'),
              onTap: () {
                Navigator.pop(context);
                ref.read(musicPlayerProvider.notifier).playTrack(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Agregar a cola'),
              onTap: () {
                Navigator.pop(context);
                ref.read(musicPlayerProvider.notifier).addToQueue(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Agregado a la cola: ${track.title}')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                track.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                track.isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
              ),
              onTap: () async {
                Navigator.pop(context);
                final wasFavorite = track.isFavorite;
                await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasFavorite
                          ? '💔 Eliminado de favoritos'
                          : '❤️ Agregado a favoritos',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información'),
              onTap: () {
                Navigator.pop(context);
                _showTrackInfo(context, track);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar información del track
  void _showTrackInfo(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Título', track.title),
            _buildInfoRow('Artista', track.artist),
            _buildInfoRow('Álbum', track.album),
            _buildInfoRow('Género', track.genre),
            _buildInfoRow(
              'Duración',
              DurationFormatter.formatMilliseconds(track.durationMs),
            ),
            _buildInfoRow('Reproducido', '${track.playCount} veces'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Widget individual para cada track en la lista
/// Separado para evitar reconstrucciones innecesarias
class _TrackListItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const _TrackListItem({
    required Key key,
    required this.track,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : (isPlaying
                  ? Icon(
                      Icons.graphic_eq,
                      color: AppColors.primary,
                    )
                  : (track.coverArtPath != null &&
                     File(track.coverArtPath!).existsSync()
                      ? Image.file(
                          File(track.coverArtPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.music_note,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            );
                          },
                        )
                      : Icon(
                          Icons.music_note,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ))),
        ),
      ),
      title: Text(
        track.title,
        style: AppTextStyles.body1(context).copyWith(
          color: isPlaying ? AppColors.primary : null,
          fontWeight: isPlaying ? FontWeight.w600 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${track.artist} • ${track.album}',
        style: AppTextStyles.caption(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DurationFormatter.formatMilliseconds(track.durationMs),
            style: AppTextStyles.caption(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: onMorePressed,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

