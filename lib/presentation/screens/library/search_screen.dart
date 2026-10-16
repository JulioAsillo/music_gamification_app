import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/track.dart';
import '../../providers/tracks_provider.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/favorites_provider.dart';

/// Provider para el query de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider para los resultados de búsqueda
final searchResultsProvider = FutureProvider<List<Track>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(allTracksProvider.future);
  }
  return ref.watch(searchTracksProvider(query).future);
});

/// Pantalla de búsqueda de música
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: AppTextStyles.body1(context),
          decoration: InputDecoration(
            hintText: 'Buscar canciones, artistas, álbumes...',
            hintStyle: AppTextStyles.body1(context).copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: searchResults.when(
        data: (tracks) {
          if (query.isEmpty) {
            return _buildRecentSearches(context);
          }

          if (tracks.isEmpty) {
            return _buildNoResults(context, query);
          }

          return _buildSearchResults(context, tracks, query);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca tu música favorita',
            style: AppTextStyles.heading3(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba buscar por título, artista o álbum',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: AppTextStyles.heading3(context),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay canciones que coincidan con "$query"',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Track> tracks, String query) {
    final currentTrack = ref.watch(currentTrackProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con contador
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${tracks.length} resultado${tracks.length != 1 ? 's' : ''}',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Reproducir todo'),
                onPressed: () {
                  ref.read(musicPlayerProvider.notifier).playTracks(tracks);
                },
              ),
            ],
          ),
        ),

        // Lista de resultados
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isPlaying = currentTrack?.id == track.id;

              return _buildTrackTile(context, track, isPlaying, index, tracks);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    Track track,
    bool isPlaying,
    int index,
    List<Track> tracks,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isPlaying
            ? Icon(Icons.graphic_eq, color: AppColors.primary)
            : Icon(
                Icons.music_note,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
      ),
      title: Text(
        _highlightSearchTerm(track.title, ref.watch(searchQueryProvider)),
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
            icon: Icon(
              track.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: track.isFavorite ? AppColors.accent : null,
            ),
            onPressed: () async {
              await ref.read(favoritesNotifierProvider.notifier)
                  .toggleFavorite(track.id!);
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
    );
  }

  String _highlightSearchTerm(String text, String query) {
    // Por ahora solo retorna el texto, pero puedes implementar highlighting más tarde
    return text;
  }
}

