import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/track.dart';
import '../providers/favorites_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlists_provider.dart';
import 'ui/ui.dart';

/// Menú de acciones de una canción (mantener presionada una fila o "⋯").
Future<void> showTrackActions(BuildContext context, WidgetRef ref, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) {
      final tt = Theme.of(sheetContext).textTheme;
      final messenger = ScaffoldMessenger.of(context);

      void done(String msg) {
        Navigator.of(sheetContext).pop();
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  TrackCover.track(track, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleMedium),
                        Text('${track.artist} • ${track.album}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Reproducir'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(musicPlayerProvider.notifier).playTrack(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Agregar a la cola'),
              onTap: () {
                ref.read(musicPlayerProvider.notifier).addToQueue(track);
                done('Agregada a la cola');
              },
            ),
            if (track.id != null)
              ListTile(
                leading: Icon(track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                title: Text(track.isFavorite ? 'Quitar de favoritas' : 'Agregar a favoritas'),
                onTap: () async {
                  await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!);
                  done(track.isFavorite ? 'Quitada de favoritas' : 'Agregada a favoritas');
                },
              ),
            if (track.id != null)
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Agregar a una playlist'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPlaylist(context, ref, track);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _pickPlaylist(BuildContext context, WidgetRef ref, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, ref, _) {
        final playlists = ref.watch(allPlaylistsProvider);
        final tt = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: playlists.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e')),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    'Aún no tienes playlists. Créalas desde Biblioteca → Playlists.',
                    style: tt.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text('Agregar a…', style: tt.titleLarge),
                  ),
                  for (final pl in list)
                    ListTile(
                      leading: const Icon(Icons.queue_music_rounded),
                      title: Text(pl.name),
                      subtitle: Text('${pl.trackCount} ${pl.trackCount == 1 ? 'canción' : 'canciones'}'),
                      onTap: () async {
                        final ok = await ref.read(playlistsNotifierProvider.notifier).addTrackToPlaylist(
                              playlistId: pl.id!,
                              trackId: track.id!,
                            );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Agregada a ${pl.name}' : 'Ya estaba en ${pl.name}')),
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
