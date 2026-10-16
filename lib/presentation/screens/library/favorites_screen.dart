import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/track.dart';
import '../../providers/tracks_provider.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/favorites_provider.dart';

/// Pantalla de canciones favoritas
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final favoritesAsync = ref.watch(watchFavoriteTracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favoritos',
          style: AppTextStyles.heading2(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Reproducir todo aleatorio',
            onPressed: () {
              favoritesAsync.whenData((tracks) {
                if (tracks.isNotEmpty) {
                  ref.read(musicPlayerProvider.notifier).playTracks(
                    tracks..shuffle(),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildFavoritesList(context, ref, tracks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.accent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos',
            style: AppTextStyles.heading2(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Marca canciones como favoritas\npara verlas aquí',
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, WidgetRef ref, List<Track> tracks) {
    final currentTrack = ref.watch(currentTrackProvider);
    final playerState = ref.watch(musicPlayerProvider);
    final isLoadingTrack = playerState.isLoading;

    return ListView.builder(
      key: const PageStorageKey<String>('favorites_list'),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: tracks.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying = currentTrack?.id == track.id;
        final isLoading = isLoadingTrack && playerState.currentTrack?.id == track.id;

        return Dismissible(
          key: Key('fav_${track.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.favorite_border, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${track.title} eliminado de favoritos'),
                  action: SnackBarAction(
                    label: 'Deshacer',
                    onPressed: () {
                      ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!);
                    },
                  ),
                ),
              );
            }
            return true;
          },
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      )
                    : (isPlaying
                        ? Icon(Icons.graphic_eq, color: AppColors.accent)
                        : (track.coverArtPath != null &&
                           File(track.coverArtPath!).existsSync()
                            ? Stack(
                                children: [
                                  Image.file(
                                    File(track.coverArtPath!),
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.favorite, color: AppColors.accent);
                                    },
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Icon(
                                      Icons.favorite,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Icon(Icons.favorite, color: AppColors.accent))),
              ),
            ),
            title: Text(
              track.title,
              style: AppTextStyles.body1(context).copyWith(
                color: isPlaying ? AppColors.accent : null,
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
                  onPressed: () {
                    _showTrackOptions(context, ref, track);
                  },
                ),
              ],
            ),
            onTap: () {
              ref.read(musicPlayerProvider.notifier).playTracks(
                tracks,
                initialIndex: index,
              );
            },
          ),
        );
      },
    );
  }

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
              leading: const Icon(Icons.favorite_border),
              title: const Text('Quitar de favoritos'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💔 Eliminado de favoritos'),
                      duration: Duration(seconds: 2),
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

