import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/track.dart';
import '../providers/music_player_provider.dart';
import 'track_actions.dart';
import 'ui/ui.dart';

/// Lista de canciones con la fila resumen del diseño:
/// "12 canciones · 1 h 50 min            [⤮ Aleatorio]".
///
/// Tocar una fila reproduce la lista desde esa canción; mantenerla
/// presionada abre el menú de acciones.
class TrackListView extends ConsumerWidget {
  const TrackListView({
    super.key,
    required this.tracks,
    this.header,
    this.emptyMessage = 'No hay canciones aquí.',
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  final List<Track> tracks;

  /// Contenido opcional encima de la fila resumen (p. ej. cabecera de álbum).
  final Widget? header;
  final String emptyMessage;
  final EdgeInsetsGeometry padding;

  static void playShuffled(WidgetRef ref, List<Track> tracks) {
    if (tracks.isEmpty) return;
    final shuffled = List<Track>.of(tracks)..shuffle(Random());
    ref.read(musicPlayerProvider.notifier).playTracks(shuffled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final currentId = ref.watch(currentTrackProvider.select((t) => t?.id));
    final totalMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final extra = header == null ? 1 : 2;

    return ListView.builder(
      padding: padding,
      itemCount: tracks.isEmpty ? extra + 1 : tracks.length + extra,
      itemBuilder: (context, i) {
        if (header != null && i == 0) return header!;
        if (i == extra - 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${Fmt.songs(tracks.length)} · ${Fmt.totalDuration(totalMs)}',
                    style: tt.bodySmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: tracks.isEmpty ? null : () => playShuffled(ref, tracks),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Aleatorio'),
                ),
              ],
            ),
          );
        }
        if (tracks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Text(emptyMessage, textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: p.text2)),
          );
        }
        final index = i - extra;
        final track = tracks[index];
        return SongTile(
          key: ValueKey(track.id ?? track.filePath),
          leading: TrackCover.track(track),
          title: track.title,
          subtitle: '${track.artist} • ${track.album}',
          duration: Fmt.trackDuration(track.durationMs),
          isPlaying: track.id != null && track.id == currentId,
          onTap: () => ref.read(musicPlayerProvider.notifier).playTracks(tracks, initialIndex: index),
          onLongPress: () => showTrackActions(context, ref, track),
        );
      },
    );
  }
}
