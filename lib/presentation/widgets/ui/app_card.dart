import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Variante de fondo de [AppCard].
enum AppCardTone {
  /// Fondo `card` (tarjetas destacadas: Nivel, estadísticas, logros).
  card,

  /// Fondo `surface` con borde `divider` (tarjetas secundarias: Próximo logro).
  surface,
}

/// Tarjeta base del sistema de diseño.
///
/// Si recibe [onTap] se vuelve pulsable con ripple recortado al radio.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = AppCardTone.card,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Borde explícito (p. ej. dorado en logros desbloqueados).
  /// Si es null, el tono `surface` usa `divider` y el tono `card` no lleva borde.
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = tone == AppCardTone.card ? p.card : p.surface;
    final border = borderColor ?? (tone == AppCardTone.surface ? p.divider : null);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border, width: borderWidth),
    );

    return Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
