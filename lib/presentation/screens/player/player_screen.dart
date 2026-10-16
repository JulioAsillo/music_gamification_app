import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/tracks_provider.dart';

/// 🎵 Pantalla del reproductor expandido
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerProvider);
    final currentTrack = playerState.currentTrack;

    if (currentTrack == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No hay música reproduciéndose'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de cerrar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Reproduciendo',
                    style: AppTextStyles.body1(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showOptionsMenu(context, ref, currentTrack.id!);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cover Art
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'cover_${currentTrack.id}',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: currentTrack.coverArtPath != null &&
                             File(currentTrack.coverArtPath!).existsSync()
                          ? Image.file(
                              File(currentTrack.coverArtPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.music_note,
                                    size: 120,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.music_note,
                                size: 120,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Info de la canción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: AppTextStyles.heading2(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentTrack.artist,
                              style: AppTextStyles.body1(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Consumer para observar cambios en tiempo real del favorito
                      Consumer(
                        builder: (context, ref, child) {
                          // Observar los tracks actualizados para obtener el estado real de favorito
                          final tracksAsync = ref.watch(watchAllTracksProvider);
                          final isFavorite = tracksAsync.whenOrNull(
                            data: (tracks) => tracks
                                .firstWhere((t) => t.id == currentTrack.id,
                                    orElse: () => currentTrack)
                                .isFavorite,
                          ) ?? currentTrack.isFavorite;

                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            iconSize: 32,
                            onPressed: () async {
                              await ref.read(favoritesNotifierProvider.notifier)
                                  .toggleFavorite(currentTrack.id!);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFavorite
                                          ? '💔 Eliminado de favoritos'
                                          : '❤️ Agregado a favoritos',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Barra de progreso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: playerState.progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        if (playerState.duration != null) {
                          final position = playerState.duration! * value;
                          ref.read(musicPlayerProvider.notifier).seek(position);
                        }
                      },
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DurationFormatter.format(playerState.position),
                          style: AppTextStyles.caption(context),
                        ),
                        Text(
                          DurationFormatter.format(
                            playerState.duration ?? Duration.zero,
                          ),
                          style: AppTextStyles.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Controles principales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playerState.shuffleEnabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    iconSize: 28,
                    onPressed: () {
                      ref.read(musicPlayerProvider.notifier).toggleShuffle();
                    },
                  ),

                  // Botón anterior
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 48,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimary
                        : Colors.black87,
                    onPressed: playerState.hasPrevious
                        ? () => ref.read(musicPlayerProvider.notifier).skipToPrevious()
                        : null,
                  ),

                  // Botón play/pause
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.accent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerState.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(musicPlayerProvider.notifier).playPause();
                      },
                    ),
                  ),

                  // Botón siguiente
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 48,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimary
                        : Colors.black87,
                    onPressed: playerState.hasNext
                        ? () => ref.read(musicPlayerProvider.notifier).skipToNext()
                        : null,
                  ),

                  // Botón repeat
                  IconButton(
                    icon: Icon(
                      playerState.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: playerState.loopMode != LoopMode.off
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    iconSize: 28,
                    onPressed: () {
                      ref.read(musicPlayerProvider.notifier).toggleLoopMode();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botón de cola de reproducción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(
                  'Cola de reproducción',
                  style: AppTextStyles.body1(context),
                ),
                subtitle: Text(
                  '${playerState.queue.length} canciones',
                  style: AppTextStyles.caption(context),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showQueueBottomSheet(context, ref);
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Mostrar menú de opciones
  void _showOptionsMenu(BuildContext context, WidgetRef ref, int trackId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Agregar a playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar agregar a playlist
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar compartir
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Mostrar info del track
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar cola de reproducción
  void _showQueueBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final playerState = ref.watch(musicPlayerProvider);
          final queue = playerState.queue;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cola de reproducción',
                        style: AppTextStyles.heading3(context),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Limpiar cola
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Lista de canciones
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = index == playerState.currentIndex;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isCurrent
                              ? Icon(
                                  Icons.graphic_eq,
                                  color: AppColors.primary,
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                ),
                        ),
                        title: Text(
                          track.title,
                          style: AppTextStyles.body1(context).copyWith(
                            color: isCurrent ? AppColors.primary : null,
                            fontWeight: isCurrent ? FontWeight.w600 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          style: AppTextStyles.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            // TODO: Eliminar de la cola
                          },
                        ),
                        onTap: () {
                          ref.read(musicPlayerProvider.notifier).skipToIndex(index);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

