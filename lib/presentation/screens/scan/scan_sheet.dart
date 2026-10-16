import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/music_scanner_service.dart';
import '../../providers/music_scanner_provider.dart';
import '../../widgets/ui/ui.dart';

/// Abre el bottom sheet de escaneo de música (diseño "Escanear").
///
/// Se usa desde Biblioteca (botón de escanear) y desde Perfil
/// (Carpetas de música). Reemplaza a la antigua `MusicScanScreen`.
Future<void> showScanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const ScanSheet(),
  );
}

class ScanSheet extends ConsumerWidget {
  const ScanSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(musicScannerProvider);
    final notifier = ref.read(musicScannerProvider.notifier);
    final p = context.palette;
    final tt = Theme.of(context).textTheme;

    final status = s.progress.status;
    final isDone = status == ScanStatus.completed && !s.isScanning && !s.isSavingToDb;
    final isError = status == ScanStatus.error || (s.errorMessage != null && !s.isScanning);
    final isBusy = s.isScanning || s.isSavingToDb;

    final IconData icon;
    final Color iconColor;
    final String title;
    final String body;

    if (isBusy) {
      icon = Icons.graphic_eq_rounded;
      iconColor = p.accent;
      title = s.isSavingToDb ? 'Guardando en tu biblioteca…' : 'Escaneando…';
      final found = s.songs.length;
      body = '$found ${found == 1 ? 'canción encontrada' : 'canciones encontradas'}';
    } else if (isError) {
      icon = Icons.error_outline_rounded;
      iconColor = AppPalette.error;
      title = 'No se pudo escanear';
      body = s.errorMessage ?? s.progress.errorMessage ?? 'Ocurrió un error inesperado.';
    } else if (isDone) {
      icon = Icons.check_circle_rounded;
      iconColor = AppPalette.success;
      final found = s.progress.foundAudioFiles;
      title = '$found ${found == 1 ? 'canción encontrada' : 'canciones encontradas'}';
      body = 'Tu biblioteca está actualizada. Las canciones nuevas ya aparecen en Biblioteca.';
    } else {
      icon = Icons.folder_outlined;
      iconColor = p.accent;
      title = 'Escanear música';
      body = s.hasPermission
          ? 'Buscaremos archivos MP3, FLAC, M4A y OGG en tu dispositivo.'
          : 'Buscaremos archivos MP3, FLAC, M4A y OGG en tu dispositivo. '
              'Necesitamos permiso de almacenamiento.';
    }

    final progressValue = s.progress.totalFiles > 0 ? s.progress.progress : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(title, style: tt.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: p.text2, height: 1.4),
            ),
            if (isBusy) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: progressValue, minHeight: 6),
              ),
              if (s.progress.currentPath.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  s.progress.currentPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall,
                ),
              ],
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: isDone
                  ? FilledButton(
                      onPressed: () {
                        notifier.clearSongs();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Listo'),
                    )
                  : FilledButton(
                      onPressed: isBusy ? null : notifier.startScan,
                      child: Text(
                        isBusy
                            ? 'Escaneando…'
                            : isError
                                ? 'Reintentar'
                                : s.hasPermission
                                    ? 'Escanear'
                                    : 'Conceder y escanear',
                      ),
                    ),
            ),
            if (isError && !s.hasPermission) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: notifier.openSettings,
                child: const Text('Abrir ajustes del sistema'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
