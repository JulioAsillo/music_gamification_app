import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../providers/music_player_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/tracks_provider.dart';
import '../screens/player/player_screen.dart';

/// 🎵 Mini reproductor que aparece en la parte inferior
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(musicPlayerProvider);
    final currentTrack = playerState.currentTrack;

    // No mostrar si no hay track
    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Abrir reproductor expandido
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlayerScreen(),
          ),
        );
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barra de progreso
            LinearProgressIndicator(
              value: playerState.progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Contenido del mini player
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Cover art
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: currentTrack.coverArtPath != null &&
                               File(currentTrack.coverArtPath!).existsSync()
                            ? Image.file(
                                File(currentTrack.coverArtPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.music_note,
                                    color: AppColors.primary,
                                    size: 28,
                                  );
                                },
                              )
                            : Icon(
                                Icons.music_note,
                                color: AppColors.primary,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info del track
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentTrack.title,
                            style: AppTextStyles.body1(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTrack.artist,
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Controles
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón de favorito con Consumer para actualizaciones en tiempo real
                        Consumer(
                          builder: (context, ref, child) {
                            final tracksAsync = ref.watch(watchAllTracksProvider);
                            final isFavorite = tracksAsync.whenOrNull(
                              data: (tracks) => tracks
                                  .firstWhere((t) => t.id == currentTrack.id,
                                      orElse: () => currentTrack)
                                  .isFavorite,
                            ) ?? currentTrack.isFavorite;

                            return IconButton(
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                              ),
                              iconSize: 24,
                              color: isFavorite ? AppColors.accent : AppColors.textSecondary,
                              onPressed: () async {
                                await ref.read(favoritesNotifierProvider.notifier)
                                    .toggleFavorite(currentTrack.id!);
                              },
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        // Mostrar indicador de carga si está cargando
                        if (playerState.isLoading)
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        else ...[
                          // Botón play/pause (más grande y centrado)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                playerState.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              iconSize: 28,
                              color: AppColors.primary,
                              onPressed: () {
                                ref.read(musicPlayerProvider.notifier).playPause();
                              },
                            ),
                          ),
                        ],

                        const SizedBox(width: 4),

                        // Botón siguiente
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: const Icon(Icons.skip_next),
                          iconSize: 28,
                          onPressed: playerState.hasNext
                              ? () => ref.read(musicPlayerProvider.notifier).skipToNext()
                              : null,
                          color: playerState.hasNext
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textPrimary
                                  : Colors.black87)
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

