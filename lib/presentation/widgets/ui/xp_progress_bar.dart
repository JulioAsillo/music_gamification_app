import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Barra de progreso del diseño (XP de nivel, progreso de logros, reproductor).
///
/// Pista `divider`, relleno con el acento (o [color]). Anima los cambios de valor.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  /// Progreso entre 0.0 y 1.0 (se recorta si sale del rango).
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final double v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    final radius = BorderRadius.circular(height / 2);

    return Semantics(
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.divider),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: v),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color ?? p.accent, borderRadius: radius),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
