import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/models/track.dart';

/// Portada de canción.
///
/// Si hay carátula ([imagePath], archivo guardado al escanear) la muestra;
/// si no, pinta uno de los gradientes del diseño elegido de forma estable a
/// partir de [seed] (el id del track), así la misma canción siempre tiene
/// el mismo color.
class TrackCover extends StatelessWidget {
  const TrackCover({
    super.key,
    required this.seed,
    this.size = 44,
    this.radius,
    this.imagePath,
    this.showIcon = false,
  });

  /// Atajo para construir la portada de un [Track].
  factory TrackCover.track(
    Track track, {
    Key? key,
    double size = 44,
    double? radius,
    bool showIcon = false,
  }) {
    return TrackCover(
      key: key,
      seed: track.id ?? track.title.hashCode,
      size: size,
      radius: radius,
      imagePath: track.coverArtPath,
      showIcon: showIcon,
    );
  }

  final int seed;

  /// Lado del cuadrado. `double.infinity` ocupa el ancho disponible (cuadrado).
  final double size;

  /// Radio de las esquinas. Por defecto escala con el tamaño (44 → 10, 120 → 16).
  final double? radius;
  final String? imagePath;

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
    final path = imagePath;
    final hasArt = path != null && path.isNotEmpty;

    Widget gradient(double iconBase) => _GradientCover(seed: seed, iconBase: iconBase, showIcon: showIcon);

    Widget content(double side) => hasArt
        ? Image.file(
            File(path!),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: side.isFinite ? (side * MediaQuery.devicePixelRatioOf(context)).round() : null,
            errorBuilder: (_, _, _) => gradient(side),
          )
        : gradient(side);

    if (!size.isFinite) {
      return LayoutBuilder(
        builder: (context, c) => ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: AspectRatio(aspectRatio: 1, child: content(c.maxWidth)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: SizedBox.square(dimension: size, child: content(size)),
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.seed, required this.iconBase, required this.showIcon});

  final int seed;
  final double iconBase;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: TrackCover.gradientFor(seed)),
      child: showIcon
          ? Center(
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: (iconBase.isFinite ? iconBase : 240) * 0.32,
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
