import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/track.dart';
import '../../providers/tracks_provider.dart';
import '../../providers/music_player_provider.dart';

enum GroupingType {
  albums,
  artists,
}

/// Pantalla de biblioteca agrupada por álbum o artista
class GroupedLibraryScreen extends ConsumerStatefulWidget {
  final GroupingType groupingType;

  const GroupedLibraryScreen({
    super.key,
    required this.groupingType,
  });

  @override
  ConsumerState<GroupedLibraryScreen> createState() => _GroupedLibraryScreenState();
}

class _GroupedLibraryScreenState extends ConsumerState<GroupedLibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(allTracksProvider);
    final title = widget.groupingType == GroupingType.albums ? 'Álbumes' : 'Artistas';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return _buildEmptyState(context, title);
          }

          final groupedData = _groupTracks(tracks);
          return _buildGroupedList(groupedData, tracks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.groupingType == GroupingType.albums
                ? Icons.album
                : Icons.person,
            size: 80,
            color: AppColors.accentDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay $title',
            style: AppTextStyles.heading2(context),
          ),
        ],
      ),
    );
  }

  Map<String, List<Track>> _groupTracks(List<Track> tracks) {
    final Map<String, List<Track>> grouped = {};

    for (final track in tracks) {
      final key = widget.groupingType == GroupingType.albums
          ? track.album
          : track.artist;

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(track);
    }

    // Ordenar por nombre
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedMap = <String, List<Track>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  Widget _buildGroupedList(Map<String, List<Track>> groupedData, List<Track> allTracks) {
    final entries = groupedData.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final groupName = entry.key;
        final tracks = entry.value;

        // Obtener imagen de portada (primera pista con artwork)
        final coverTrack = tracks.firstWhere(
          (t) => t.coverArtPath != null && File(t.coverArtPath!).existsSync(),
          orElse: () => tracks.first,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverTrack.coverArtPath != null &&
                        File(coverTrack.coverArtPath!).existsSync()
                    ? Image.file(
                        File(coverTrack.coverArtPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            widget.groupingType == GroupingType.albums
                                ? Icons.album
                                : Icons.person,
                            color: AppColors.primary.withValues(alpha: 0.6),
                            size: 30,
                          );
                        },
                      )
                    : Icon(
                        widget.groupingType == GroupingType.albums
                            ? Icons.album
                            : Icons.person,
                        color: AppColors.primary.withValues(alpha: 0.6),
                        size: 30,
                      ),
              ),
            ),
            title: Text(
              groupName,
              style: AppTextStyles.body1(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${tracks.length} ${tracks.length == 1 ? 'canción' : 'canciones'}',
              style: AppTextStyles.caption(context),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_filled),
              color: AppColors.primary,
              iconSize: 32,
              onPressed: () {
                // Reproducir todas las canciones del grupo
                ref.read(musicPlayerProvider.notifier).playTracks(tracks);
              },
            ),
            onTap: () {
              _showGroupDetails(context, groupName, tracks);
            },
          ),
        );
      },
    );
  }

  void _showGroupDetails(BuildContext context, String groupName, List<Track> tracks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      // Cover art
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: tracks.first.coverArtPath != null &&
                                  File(tracks.first.coverArtPath!).existsSync()
                              ? Image.file(
                                  File(tracks.first.coverArtPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      widget.groupingType == GroupingType.albums
                                          ? Icons.album
                                          : Icons.person,
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      size: 40,
                                    );
                                  },
                                )
                              : Icon(
                                  widget.groupingType == GroupingType.albums
                                      ? Icons.album
                                      : Icons.person,
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: AppTextStyles.heading3(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tracks.length} ${tracks.length == 1 ? 'canción' : 'canciones'}',
                              style: AppTextStyles.caption(context),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_filled),
                        color: AppColors.primary,
                        iconSize: 40,
                        onPressed: () {
                          Navigator.pop(context); // Cerrar modal para ver Mini Player
                          ref.read(musicPlayerProvider.notifier).playTracks(tracks);
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Lista de tracks
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currentTrack = ref.watch(currentTrackProvider);

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isPlaying = currentTrack?.id == track.id;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: isPlaying
                                  ? Icon(
                                      Icons.graphic_eq,
                                      color: AppColors.primary,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyles.bodySmall(context),
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
                              widget.groupingType == GroupingType.albums
                                  ? track.artist
                                  : track.album,
                              style: AppTextStyles.caption(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context); // Cerrar modal para ver Mini Player
                              ref.read(musicPlayerProvider.notifier).playTracks(
                                    tracks,
                                    initialIndex: index,
                                  );
                            },
                          );
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

