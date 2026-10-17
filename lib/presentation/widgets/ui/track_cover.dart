import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/models/track.dart';

/// Portada de canción.
///
/// Si la canción trae carátula ([imagePath], extraída del archivo al
/// escanear) la muestra con un fundido suave; mientras carga, o si no hay
/// imagen, pinta uno de los gradientes del diseño elegido de forma estable a
/// partir de [seed] (el id del track): la misma canción siempre tiene el
/// mismo color.
///
/// Las portadas grandes (≥ 96 px o a todo el ancho) llevan una sombra suave
/// para que la carátula "flote" sobre el fondo.
class TrackCover extends StatelessWidget {
  const TrackCover({
    super.key,
    required this.seed,
    this.size = 44,
    this.radius,
    this.imagePath,
    this.showIcon = false,
    this.elevated,
  });

  /// Atajo para construir la portada de un [Track].
  factory TrackCover.track(
    Track track, {
    Key? key,
    double size = 44,
    double? radius,
    bool showIcon = false,
    bool? elevated,
  }) {
    return TrackCover(
      key: key,
      seed: track.id ?? track.title.hashCode,
      size: size,
      radius: radius,
      imagePath: track.coverArtPath,
      showIcon: showIcon,
      elevated: elevated,
    );
  }

  final int seed;

  /// Lado del cuadrado. `double.infinity` ocupa el ancho disponible (cuadrado).
  final double size;

  /// Radio de las esquinas. Por defecto escala con el tamaño (44 → 10, 120 → 16).
  final double? radius;
  final String? imagePath;

  /// Muestra la nota musical blanca centrada cuando no hay carátula
  /// (portadas grandes del diseño).
  final bool showIcon;

  /// Sombra bajo la portada. Por defecto, solo en portadas grandes.
  final bool? elevated;

  bool get hasArt => imagePath != null && imagePath!.isNotEmpty;

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
    final isLarge = !size.isFinite || size >= 96;
    final r = radius ?? (size <= 48 ? 10.0 : size <= 128 ? 16.0 : 28.0);
    final shadow = (elevated ?? isLarge)
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: isLarge ? 24 : 10,
              offset: Offset(0, isLarge ? 10 : 4),
            ),
          ]
        : null;

    Widget square(double side) {
      final placeholder = _GradientCover(seed: seed, iconBase: side, showIcon: showIcon);
      final content = hasArt
          ? _CoverImage(
              path: imagePath!,
              cacheSide: side.isFinite ? (side * MediaQuery.devicePixelRatioOf(context)).round() : 1024,
              placeholder: placeholder,
            )
          : placeholder;

      return DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(r), boxShadow: shadow),
        child: ClipRRect(borderRadius: BorderRadius.circular(r), child: content),
      );
    }

    if (!size.isFinite) {
      return LayoutBuilder(
        builder: (context, c) => AspectRatio(aspectRatio: 1, child: square(c.maxWidth)),
      );
    }
    return SizedBox.square(dimension: size, child: square(size));
  }
}

/// Carátula desde archivo con fundido de entrada. Si el archivo no existe o
/// no se puede decodificar, queda el [placeholder] (gradiente).
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.path, required this.cacheSide, required this.placeholder});

  final String path;
  final int cacheSide;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      cacheWidth: cacheSide,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
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
                color: Colors.white.withValues(alpha: 0.9),
                size: (iconBase.isFinite ? iconBase : 240) * 0.32,
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
