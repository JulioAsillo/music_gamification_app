import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../providers/music_player_provider.dart';
import 'ui/ui.dart';

/// Mini reproductor persistente sobre la barra de navegación.
///
/// Portada, título/artista, play/pausa y siguiente; barra de progreso fina
/// abajo. Al tocarlo abre el reproductor completo.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();

    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final isPlaying = ref.watch(musicPlayerProvider.select((s) => s.isPlaying));
    final hasNext = ref.watch(musicPlayerProvider.select((s) => s.hasNext));
    final progress = ref.watch(musicPlayerProvider.select((s) => s.progress));
    final notifier = ref.read(musicPlayerProvider.notifier);

    return Material(
      color: p.surface,
      child: InkWell(
        onTap: () => context.push(AppRoutes.player),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Hero(
                    tag: 'player-cover',
                    child: TrackCover.track(track, size: 40, radius: 8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                    color: p.text,
                    onPressed: notifier.playPause,
                  ),
                  IconButton(
                    tooltip: 'Siguiente',
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    color: p.text,
                    onPressed: hasNext ? notifier.skipToNext : null,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0).toDouble(),
                backgroundColor: p.divider,
                color: p.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
