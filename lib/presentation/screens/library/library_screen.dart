import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/playlist.dart';
import '../../../data/models/track.dart';
import '../../providers/filters_provider.dart';
import '../../providers/playlists_provider.dart';
import '../../providers/tracks_provider.dart';
import '../../widgets/track_list_view.dart';
import '../../widgets/ui/ui.dart';
import '../playlists/create_playlist_dialog.dart';
import '../playlists/playlist_detail_screen.dart';
import '../scan/scan_sheet.dart';
import 'filters_screen.dart';
import 'track_collection_screen.dart';

/// Biblioteca (diseño "2 · Biblioteca").
///
/// Buscador + chips Canciones / Artistas / Álbumes / Favoritas / Playlists.
/// El buscador filtra la pestaña activa.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _tabs = ['Canciones', 'Artistas', 'Álbumes', 'Favoritas', 'Playlists'];

  final _search = TextEditingController();
  int _tab = 0;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Track t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        t.artist.toLowerCase().contains(q) ||
        t.album.toLowerCase().contains(q);
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final hasFilters = ref.watch(hasActiveFiltersProvider);
    final libraryEmpty = ref.watch(watchAllTracksProvider).value?.isEmpty ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const Expanded(child: ScreenTitle('Biblioteca')),
                  if (_tab == 0 && !libraryEmpty) ...[
                    Badge(
                      isLabelVisible: hasFilters,
                      smallSize: 10,
                      child: CircleIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Ordenar y filtrar',
                        onPressed: () => _push(const FiltersScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CircleIconButton(
                    icon: Icons.document_scanner_outlined,
                    tooltip: 'Escanear música',
                    onPressed: () => showScanSheet(context),
                  ),
                ],
              ),
            ),
            if (libraryEmpty)
              Expanded(child: _EmptyLibrary(onScan: () => showScanSheet(context)))
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Canciones, artistas, álbumes',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppFilterChipRow(
                labels: _tabs,
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildTab()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _AsyncTracks(
          value: ref.watch(watchFilteredAndSortedTracksProvider),
          builder: (tracks) => TrackListView(
            tracks: tracks.where(_matches).toList(),
            emptyMessage: _query.isEmpty ? 'No hay canciones con estos filtros.' : 'Sin resultados para "$_query".',
          ),
        );
      case 1:
        return _AsyncTracks(
          value: ref.watch(watchAllTracksProvider),
          builder: (tracks) => _GroupList(
            groups: _group(tracks, (t) => t.artist),
            round: true,
            subtitle: (g) => Fmt.songs(g.tracks.length),
            onTap: (g) => _push(TrackCollectionScreen(kind: CollectionKind.artist, name: g.name)),
          ),
        );
      case 2:
        return _AsyncTracks(
          value: ref.watch(watchAllTracksProvider),
          builder: (tracks) => _AlbumGrid(
            groups: _group(tracks, (t) => t.album),
            onTap: (g) => _push(TrackCollectionScreen(kind: CollectionKind.album, name: g.name)),
          ),
        );
      case 3:
        return _AsyncTracks(
          value: ref.watch(watchFavoriteTracksProvider),
          builder: (tracks) => TrackListView(
            tracks: tracks.where(_matches).toList(),
            emptyMessage: 'Aún no tienes favoritas. Mantén presionada una canción para agregarla.',
          ),
        );
      default:
        return _PlaylistList(
          query: _query,
          onOpen: (pl) => _push(PlaylistDetailScreen(playlistId: pl.id!)),
        );
    }
  }

  List<_Group> _group(List<Track> tracks, String Function(Track) key) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final raw = key(t).trim();
      final k = raw.isEmpty ? 'Desconocido' : raw;
      (map[k] ??= []).add(t);
    }
    final q = _query.toLowerCase();
    final groups = map.entries
        .where((e) =>
            q.isEmpty ||
            e.key.toLowerCase().contains(q) ||
            e.value.any((t) => t.artist.toLowerCase().contains(q)))
        .map((e) => _Group(e.key, e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }
}

class _Group {
  _Group(this.name, this.tracks);
  final String name;
  final List<Track> tracks;

  /// Track con carátula si existe (para la portada del grupo).
  Track get coverTrack => tracks.firstWhere(
        (t) => t.coverArtPath != null && t.coverArtPath!.isNotEmpty,
        orElse: () => tracks.first,
      );
}

/// Envuelve un AsyncValue de tracks con estados de carga y error.
class _AsyncTracks extends StatelessWidget {
  const _AsyncTracks({required this.value, required this.builder});

  final AsyncValue<List<Track>> value;
  final Widget Function(List<Track>) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text('No se pudo cargar: $e')),
      ),
      data: builder,
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groups,
    required this.subtitle,
    required this.onTap,
    this.round = false,
  });

  final List<_Group> groups;
  final String Function(_Group) subtitle;
  final void Function(_Group) onTap;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (groups.isEmpty) {
      return Center(child: Text('Sin resultados.', style: tt.bodyMedium));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        return SongTile(
          leading: TrackCover.track(g.coverTrack, size: 44, radius: round ? 22 : 10),
          title: g.name,
          subtitle: subtitle(g),
          trailing: Icon(Icons.chevron_right_rounded, color: context.palette.text2),
          onTap: () => onTap(g),
        );
      },
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.groups, required this.onTap});

  final List<_Group> groups;
  final void Function(_Group) onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (groups.isEmpty) {
      return Center(child: Text('Sin resultados.', style: tt.bodyMedium));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        final artist = g.tracks.map((t) => t.artist).toSet().join(', ');
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(g),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrackCover.track(g.coverTrack, size: double.infinity, radius: 16, showIcon: true),
              const SizedBox(height: 8),
              Text(g.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistList extends ConsumerWidget {
  const _PlaylistList({required this.query, required this.onOpen});

  final String query;
  final void Function(Playlist) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final playlists = ref.watch(allPlaylistsProvider);

    return playlists.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final q = query.toLowerCase();
        final list = all.where((pl) => q.isEmpty || pl.name.toLowerCase().contains(q)).toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return SongTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_rounded, color: p.accent),
                ),
                title: 'Nueva playlist',
                subtitle: all.isEmpty ? 'Agrupa tus canciones a tu manera' : '${all.length} playlists',
                onTap: () => showDialog<void>(context: context, builder: (_) => const CreatePlaylistDialog()),
              );
            }
            final pl = list[i - 1];
            return SongTile(
              leading: TrackCover(seed: pl.id ?? pl.name.hashCode, imagePath: pl.coverPath),
              title: pl.isFavorite ? '★ ${pl.name}' : pl.name,
              subtitle: Fmt.songs(pl.trackCount),
              trailing: Icon(Icons.chevron_right_rounded, color: p.text2),
              onTap: () => onOpen(pl),
            );
          },
        );
      },
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.library_music_rounded, size: 40, color: p.accent),
            ),
            const SizedBox(height: 20),
            Text('Tu biblioteca está vacía', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Escanea tu dispositivo para encontrar tu música y empezar a sumar XP.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: p.text2),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined, size: 18),
              label: const Text('Escanear música'),
            ),
          ],
        ),
      ),
    );
  }
}
