import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/track_provider.dart';
import '../scan/music_scan_screen.dart';

/// Pantalla de biblioteca de música
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTracksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Biblioteca',
          style: AppTextStyles.heading2(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtros
            },
          ),
        ],
      ),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildTracksList(tracks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MusicScanScreen(),
            ),
          );
        },
        child: const Icon(Icons.search),
        tooltip: 'Escanear música',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 80,
            color: AppColors.accentDark.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Biblioteca vacía',
            style: AppTextStyles.heading2(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón para escanear música',
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List<dynamic> tracks) {
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.music_note),
          ),
          title: Text(track.title),
          subtitle: Text('${track.artist} • ${track.album}'),
          trailing: Text(_formatDuration(track.durationMs)),
          onTap: () {
            // TODO: Reproducir canción
          },
        );
      },
    );
  }

  String _formatDuration(int durationMs) {
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
