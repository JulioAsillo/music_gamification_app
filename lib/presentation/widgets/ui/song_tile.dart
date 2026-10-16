import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Fila de canción del diseño (Biblioteca, búsqueda, playlists).
///
/// Portada 44px, título 15/600 (en color de acento si está sonando),
/// "Artista • Álbum" en texto secundario y duración a la derecha.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.duration,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  /// Normalmente un `TrackCover(size: 44)`.
  final Widget leading;
  final String title;
  final String subtitle;

  /// Duración ya formateada (`3:45`). Se omite si hay [trailing].
  final String? duration;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Reemplaza la duración (p. ej. botón de favorito o menú).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? p.accent : p.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (duration != null) ...[
                const SizedBox(width: 12),
                Text(duration!, style: tt.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
