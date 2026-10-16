import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Botón redondo de 44px con fondo `surface` (acciones del header: escanear, cerrar).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  /// Relleno con el acento (botón play del reproductor).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? p.accent : p.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: size * 0.5, color: filled ? p.onAccent : p.text),
          ),
        ),
      ),
    );
  }
}
