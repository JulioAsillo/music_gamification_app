import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Portada de canción.
///
/// Si hay carátula ([artwork]) la muestra; si no, pinta uno de los gradientes
/// del diseño elegido de forma estable a partir de [seed] (p. ej. el id del track),
/// para que la misma canción tenga siempre el mismo color.
class TrackCover extends StatelessWidget {
  const TrackCover({
    super.key,
    required this.seed,
    this.size = 44,
    this.radius,
    this.artwork,
    this.showIcon = false,
  });

  final int seed;
  final double size;

  /// Radio de las esquinas. Por defecto escala con el tamaño (44 → 10, 120 → 16).
  final double? radius;
  final Uint8List? artwork;

  /// Muestra la nota musical blanca centrada (portadas grandes del diseño).
  final bool showIcon;

  static LinearGradient gradientFor(int seed) {
    final colors = AppPalette.coverGradients[seed.abs() % AppPalette.coverGradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = radius ?? (size <= 48 ? 10.0 : size <= 128 ? 16.0 : 28.0);
    final hasArt = artwork != null && artwork!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox.square(
        dimension: size,
        child: hasArt
            ? Image.memory(
                artwork!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => _GradientCover(seed: seed, size: size, showIcon: showIcon),
              )
            : _GradientCover(seed: seed, size: size, showIcon: showIcon),
      ),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.seed, required this.size, required this.showIcon});

  final int seed;
  final double size;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: TrackCover.gradientFor(seed)),
      child: showIcon
          ? Center(child: Icon(Icons.music_note_rounded, color: Colors.white, size: size * 0.32))
          : const SizedBox.expand(),
    );
  }
}
