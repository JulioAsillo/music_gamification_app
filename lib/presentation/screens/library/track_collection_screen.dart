import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/track.dart';
import '../../providers/tracks_provider.dart';
import '../../widgets/track_list_view.dart';
import '../../widgets/ui/ui.dart';

enum CollectionKind { artist, album }

/// Canciones de un artista o de un álbum (se abre desde Biblioteca).
///
/// Escucha la biblioteca completa para reflejar cambios (favoritos, nuevas
/// canciones) sin recargar.
class TrackCollectionScreen extends ConsumerWidget {
  const TrackCollectionScreen({super.key, required this.kind, required this.name});

  final CollectionKind kind;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final p = context.palette;
    final all = ref.watch(watchAllTracksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const SizedBox.shrink(),
      ),
      body: all.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tracks) {
          final list = tracks
              .where((t) => kind == CollectionKind.artist ? t.artist == name : t.album == name)
              .toList()
            ..sort(_order);
          final first = list.isEmpty ? null : list.first;
          final artists = list.map((t) => t.artist).toSet();

          return TrackListView(
            tracks: list,
            header: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (first != null)
                    TrackCover.track(first, size: 96, radius: kind == CollectionKind.artist ? 48 : 16, showIcon: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind == CollectionKind.artist ? 'ARTISTA' : 'ÁLBUM',
                          style: tt.labelSmall?.copyWith(letterSpacing: 1.1, color: p.text2),
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: tt.headlineMedium?.copyWith(fontSize: 22), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (kind == CollectionKind.album && artists.isNotEmpty)
                          Text(artists.join(', '), style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (kind == CollectionKind.artist)
                          Text(Fmt.songs(list.length), style: tt.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _order(Track a, Track b) {
    if (kind == CollectionKind.artist) {
      final byAlbum = a.album.toLowerCase().compareTo(b.album.toLowerCase());
      if (byAlbum != 0) return byAlbum;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
