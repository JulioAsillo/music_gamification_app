import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/music_scanner_provider.dart';
import '../../../services/music_scanner_service.dart';
import '../../../services/metadata_extractor_service.dart';

/// 🔍 Pantalla de escaneo de música
class MusicScanScreen extends ConsumerWidget {
  const MusicScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(musicScannerProvider);
    final hasPermission = scannerState.hasPermission;
    final isScanning = scannerState.isScanning;
    final songs = scannerState.songs;
    final progress = scannerState.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Escanear Música'),
        centerTitle: true,
      ),
      body: !hasPermission
          ? _buildPermissionRequest(context, ref)
          : Column(
              children: [
                // 📊 Sección de progreso
                _buildProgressSection(context, progress, isScanning),
                
                // 🎶 Lista de canciones encontradas
                Expanded(
                  child: _buildSongsList(songs),
                ),
              ],
            ),
      floatingActionButton: hasPermission && !isScanning
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(musicScannerProvider.notifier).startScan(),
              icon: const Icon(Icons.search),
              label: const Text('Escanear'),
            )
          : null,
    );
  }

  /// 🔐 Widget para solicitar permisos
  Widget _buildPermissionRequest(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Permisos Necesarios',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Necesitamos acceso a tu almacenamiento para escanear y reproducir tu música local.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(musicScannerProvider.notifier).requestPermissions();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Conceder Permisos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Widget de progreso del escaneo
  Widget _buildProgressSection(
    BuildContext context,
    ScanProgress progress,
    bool isScanning,
  ) {
    if (!isScanning && progress.foundAudioFiles == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del escaneo
          Row(
            children: [
              if (isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.status == ScanStatus.completed
                      ? '✅ Escaneo completado'
                      : progress.currentPath.isEmpty
                          ? 'Escaneando...'
                          : 'Escaneando...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(
                context,
                '🎵 Canciones',
                '${progress.foundAudioFiles}',
              ),
              _buildStat(
                context,
                '📁 Archivos',
                '${progress.scannedFiles}',
              ),
              _buildStat(
                context,
                '📊 Progreso',
                '${(progress.progress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),

          // Barra de progreso
          if (isScanning && progress.totalFiles > 0)
            const SizedBox(height: 12),
          if (isScanning && progress.totalFiles > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
            ),

          // Ruta actual
          if (isScanning && progress.currentPath.isNotEmpty)
            const SizedBox(height: 8),
          if (isScanning && progress.currentPath.isNotEmpty)
            Text(
              progress.currentPath.length > 50
                  ? '...${progress.currentPath.substring(progress.currentPath.length - 50)}'
                  : progress.currentPath,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
      ),
    );
  }

  /// 📊 Widget de estadística
  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 🎶 Lista de canciones encontradas
  Widget _buildSongsList(List<AudioMetadata> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron canciones',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón para escanear',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongCard(context, song);
      },
    );
  }

  /// 🎵 Card de canción
  Widget _buildSongCard(BuildContext context, AudioMetadata song) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${song.artist} • ${song.album}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              MetadataExtractorService.formatDuration(song.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              MetadataExtractorService.getFileExtension(song.filePath),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
