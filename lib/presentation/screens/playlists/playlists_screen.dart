import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/playlist.dart';
import '../../providers/playlists_provider.dart';
import '../../providers/music_player_provider.dart';
import 'playlist_detail_screen.dart';
import 'create_playlist_dialog.dart';
import 'edit_playlist_dialog.dart';

/// Pantalla de gestión de playlists
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Playlists',
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: playlists.isEmpty
          ? _buildEmptyState(context)
          : _buildPlaylistsGrid(context, ref, playlists),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'playlists_create_fab',
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const CreatePlaylistDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Playlist'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            size: 80,
            color: AppColors.accentDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes playlists',
            style: AppTextStyles.heading2(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera playlist personalizada',
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsGrid(BuildContext context, WidgetRef ref, List<Playlist> playlists) {
    // Separar favoritas de las demás
    final favorites = playlists.where((p) => p.isFavorite).toList();
    final others = playlists.where((p) => !p.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (favorites.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.star, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Favoritas',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...favorites.map((playlist) => _buildPlaylistCard(context, ref, playlist)),
          const SizedBox(height: 24),
        ],
        if (others.isNotEmpty) ...[
          if (favorites.isNotEmpty)
            Text(
              'Todas las Playlists',
              style: AppTextStyles.heading3(context),
            ),
          if (favorites.isNotEmpty) const SizedBox(height: 12),
          ...others.map((playlist) => _buildPlaylistCard(context, ref, playlist)),
        ],
        const SizedBox(height: 80), // Espacio para el FAB
      ],
    );
  }

  Widget _buildPlaylistCard(BuildContext context, WidgetRef ref, Playlist playlist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: playlist.coverPath != null &&
                    File(playlist.coverPath!).existsSync()
                ? Image.file(
                    File(playlist.coverPath!),
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.queue_music,
                    color: AppColors.primary.withValues(alpha: 0.6),
                    size: 30,
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                playlist.name,
                style: AppTextStyles.body1(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (playlist.isFavorite)
              Icon(Icons.star, color: AppColors.accent, size: 18),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.description != null && playlist.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  playlist.description!,
                  style: AppTextStyles.caption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${playlist.trackCount} ${playlist.trackCount == 1 ? 'canción' : 'canciones'}',
              style: AppTextStyles.caption(context),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playlist.trackCount > 0)
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              color: AppColors.primary,
              iconSize: 32,
              onPressed: () async {
                // Reproducir playlist completa
                final tracks = await ref
                    .read(playlistsRepositoryProvider)
                    .getPlaylistTracks(playlist.id!);
                if (tracks.isNotEmpty) {
                  ref.read(musicPlayerProvider.notifier).playTracks(tracks);
                }
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        playlist.isFavorite ? Icons.star : Icons.star_border,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        playlist.isFavorite ? 'Quitar de favoritas' : 'Marcar como favorita',
                      ),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(playlistsNotifierProvider.notifier).toggleFavorite(playlist.id!);
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Editar'),
                    ],
                  ),
                  onTap: () async {
                    await Future.delayed(Duration.zero);
                    if (context.mounted) {
                      await showDialog(
                        context: context,
                        builder: (context) => EditPlaylistDialog(
                          playlistId: playlist.id!,
                          currentName: playlist.name,
                          currentDescription: playlist.description,
                        ),
                      );
                    }
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () async {
                    await Future.delayed(Duration.zero);
                    if (!context.mounted) return;

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Eliminar playlist?'),
                        content: Text('¿Estás seguro de que quieres eliminar "${playlist.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await ref.read(playlistsNotifierProvider.notifier).deletePlaylist(playlist.id!);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Playlist eliminada'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlistId: playlist.id!),
            ),
          );
        },
      ),
    );
  }
}
