import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../providers/playlists_provider.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/tracks_provider.dart';
import 'edit_playlist_dialog.dart';

/// Pantalla de detalle de una playlist
class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistProvider(playlistId));
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));

    return Scaffold(
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return const Center(child: Text('Playlist no encontrada'));
          }

          return CustomScrollView(
            slivers: [
              _buildHeader(context, ref, playlist),
              tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(context, ref),
                    );
                  }
                  return _buildTracksList(context, ref, tracks, playlist);
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, playlist) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            playlist.coverPath != null && File(playlist.coverPath!).existsSync()
                ? Image.file(
                    File(playlist.coverPath!),
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.accent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.queue_music,
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            playlist.isFavorite ? Icons.star : Icons.star_border,
            color: playlist.isFavorite ? AppColors.accent : Colors.white,
          ),
          onPressed: () {
            ref.read(playlistsNotifierProvider.notifier).toggleFavorite(playlistId);
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Editar playlist'),
                ],
              ),
              onTap: () async {
                await Future.delayed(Duration.zero);
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => EditPlaylistDialog(
                      playlistId: playlist.id,
                      currentName: playlist.name,
                      currentDescription: playlist.description,
                    ),
                  );
                }
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Eliminar playlist', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () async {
                await Future.delayed(Duration.zero);
                if (!context.mounted) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Eliminar playlist?'),
                    content: const Text('Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final success = await ref.read(playlistsNotifierProvider.notifier).deletePlaylist(playlistId);
                  if (context.mounted && success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Playlist eliminada')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Playlist vacía',
            style: AppTextStyles.heading3(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega canciones para comenzar',
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTracksDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Canciones'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(BuildContext context, WidgetRef ref, tracks, playlist) {
    final currentTrack = ref.watch(currentTrackProvider);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Header con info y botones
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playlist.description != null && playlist.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        playlist.description!,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(musicPlayerProvider.notifier).playTracks(tracks);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Reproducir Todo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddTracksDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    '${tracks.length} ${tracks.length == 1 ? 'canción' : 'canciones'}',
                    style: AppTextStyles.body1(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final track = tracks[index - 1];
          final isPlaying = currentTrack?.id == track.id;

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
                child: isPlaying
                    ? Icon(Icons.graphic_eq, color: AppColors.primary)
                    : (track.coverArtPath != null &&
                            File(track.coverArtPath!).existsSync()
                        ? Image.file(
                            File(track.coverArtPath!),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.music_note,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          )),
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
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Eliminar de la playlist', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () async {
                        await Future.delayed(Duration.zero);
                        if (!context.mounted) return;

                        final success = await ref
                            .read(playlistsNotifierProvider.notifier)
                            .removeTrackFromPlaylist(
                              playlistId: playlistId,
                              trackId: track.id!,
                            );

                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Canción eliminada de la playlist')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              ref.read(musicPlayerProvider.notifier).playTracks(
                    tracks,
                    initialIndex: index - 1,
                  );
            },
          );
        },
        childCount: tracks.length + 1,
      ),
    );
  }

  Future<void> _showAddTracksDialog(BuildContext context, WidgetRef ref) async {
    final allTracksAsync = await ref.read(allTracksProvider.future);
    final currentTracksAsync = await ref.read(playlistTracksProvider(playlistId).future);

    // IDs de tracks que ya están en la playlist
    final currentTrackIds = currentTracksAsync.map((t) => t.id).toSet();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Consumer(
                builder: (context, ref, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Agregar Canciones',
                                style: AppTextStyles.heading3(context),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: allTracksAsync.length,
                            itemBuilder: (context, index) {
                              final track = allTracksAsync[index];
                              final isAdded = currentTrackIds.contains(track.id);

                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: track.coverArtPath != null && File(track.coverArtPath!).existsSync()
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.file(
                                            File(track.coverArtPath!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.music_note,
                                                  color: AppColors.primary.withValues(alpha: 0.6));
                                            },
                                          ),
                                        )
                                      : Icon(Icons.music_note,
                                          color: AppColors.primary.withValues(alpha: 0.6)),
                                ),
                                title: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isAdded ? AppColors.primary : null,
                                    fontWeight: isAdded ? FontWeight.w600 : null,
                                  ),
                                ),
                                subtitle: Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isAdded
                                    ? Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 24,
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () async {
                                          final success = await ref
                                              .read(playlistsNotifierProvider.notifier)
                                              .addTrackToPlaylist(
                                                playlistId: playlistId,
                                                trackId: track.id!,
                                              );

                                          if (success && context.mounted) {
                                            // Actualizar el estado local
                                            setState(() {
                                              currentTrackIds.add(track.id);
                                            });

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('✅ "${track.title}" agregada'),
                                                duration: const Duration(seconds: 1),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

