import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../../core/constants/gamification.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/track.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/tracks_provider.dart';
import '../../widgets/track_actions.dart';
import '../../widgets/ui/ui.dart';

/// Reproductor completo (diseño "7 · Reproductor completo").
///
/// Se abre como ruta modal desde el mini-player y sube desde abajo.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  /// Valor del slider mientras el usuario arrastra (null = sigue al audio).
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(musicPlayerProvider);
    final notifier = ref.read(musicPlayerProvider.notifier);
    final track = state.currentTrack;

    if (track == null) {
      // La cola terminó o se limpió: no hay nada que mostrar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: p.bg);
    }

    // isFavorite en vivo (el Track de la cola puede estar desactualizado)
    final isFavorite = ref.watch(watchAllTracksProvider.select(
      (v) => v.value?.firstWhere((t) => t.id == track.id, orElse: () => track).isFavorite ?? track.isFavorite,
    ));
    final streak = ref.watch(watchUserStatsProvider).value?.currentStreakDays ?? 0;

    final totalMs = (state.duration?.inMilliseconds ?? track.durationMs).toDouble();
    final posMs = (_dragMs ?? state.position.inMilliseconds.toDouble()).clamp(0.0, totalMs <= 0 ? 1.0 : totalMs);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _PlayerBackdrop(
            coverPath: track.coverArtPath,
            tint: p.accent.withValues(alpha: isDark ? 0.33 : 0.2),
            background: p.bg,
            isDark: isDark,
          ),
          SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // ── Barra superior ──
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'REPRODUCIENDO DESDE BIBLIOTECA',
                        textAlign: TextAlign.center,
                        style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Más opciones',
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: () => showTrackActions(context, ref, track),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Portada ──
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Hero(
                        tag: 'player-cover',
                        child: TrackCover.track(track, size: double.infinity, radius: 28, showIcon: true),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Título + favorito ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.headlineMedium?.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${track.artist} · ${track.album}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(color: p.text2),
                          ),
                        ],
                      ),
                    ),
                    if (track.id != null)
                      IconButton(
                        tooltip: isFavorite ? 'Quitar de favoritas' : 'Agregar a favoritas',
                        icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                        color: isFavorite ? p.accent : p.text2,
                        onPressed: () => ref.read(favoritesNotifierProvider.notifier).toggleFavorite(track.id!),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Progreso ──
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs <= 0 ? 1 : totalMs,
                    value: posMs.toDouble(),
                    onChanged: (v) => setState(() => _dragMs = v),
                    onChangeEnd: (v) {
                      notifier.seek(Duration(milliseconds: v.round()));
                      setState(() => _dragMs = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(Fmt.trackDuration(posMs.round()), style: tt.labelSmall),
                      const Spacer(),
                      Text(Fmt.trackDuration(totalMs.round()), style: tt.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Controles ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Aleatorio',
                      icon: const Icon(Icons.shuffle_rounded),
                      color: state.shuffleEnabled ? p.accent : p.text2,
                      onPressed: notifier.toggleShuffle,
                    ),
                    IconButton(
                      tooltip: 'Anterior',
                      iconSize: 38,
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: p.text,
                      onPressed: notifier.skipToPrevious,
                    ),
                    _PlayButton(
                      isPlaying: state.isPlaying,
                      isLoading: state.isLoading,
                      onPressed: notifier.playPause,
                    ),
                    IconButton(
                      tooltip: 'Siguiente',
                      iconSize: 38,
                      icon: const Icon(Icons.skip_next_rounded),
                      color: p.text,
                      onPressed: state.hasNext || state.loopMode == LoopMode.all ? notifier.skipToNext : null,
                    ),
                    IconButton(
                      tooltip: switch (state.loopMode) {
                        LoopMode.off => 'Repetir todo',
                        LoopMode.all => 'Repetir una',
                        LoopMode.one => 'No repetir',
                      },
                      icon: Icon(state.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded),
                      color: state.loopMode == LoopMode.off ? p.text2 : p.accent,
                      onPressed: notifier.toggleLoopMode,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── XP + cola ──
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.divider),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '+${Gamification.xpPerSong} XP',
                              style: tt.labelLarge?.copyWith(color: AppPalette.success),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                streak > 0
                                    ? 'por esta canción · racha de $streak ${streak == 1 ? 'día' : 'días'} activa'
                                    : 'por esta canción',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleIconButton(
                      icon: Icons.queue_music_rounded,
                      tooltip: 'Cola de reproducción',
                      onPressed: () => _showQueue(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _QueueSheet(),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.isLoading, required this.onPressed});

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 72,
          child: Center(
            child: isLoading
                ? SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: p.onAccent),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                    color: p.onAccent,
                    semanticLabel: isPlaying ? 'Pausar' : 'Reproducir',
                  ),
          ),
        ),
      ),
    );
  }
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(musicPlayerProvider);
    final List<Track> queue = state.queue;
    final current = state.currentIndex;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Cola · ${Fmt.songs(queue.length)}', style: tt.titleLarge),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: queue.length,
              itemBuilder: (context, i) {
                final t = queue[i];
                return SongTile(
                  leading: TrackCover.track(t),
                  title: t.title,
                  subtitle: t.artist,
                  duration: Fmt.trackDuration(t.durationMs),
                  isPlaying: i == current,
                  onTap: () {
                    ref.read(musicPlayerProvider.notifier).skipToIndex(i);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo del reproductor.
///
/// Con carátula: la misma imagen muy desenfocada y atenuada, fundida hacia el
/// color de fondo (el color de la canción tiñe la pantalla). Sin carátula: el
/// degradado con el acento del diseño. Cambia con un fundido al pasar de
/// canción.
class _PlayerBackdrop extends StatelessWidget {
  const _PlayerBackdrop({
    required this.coverPath,
    required this.tint,
    required this.background,
    required this.isDark,
  });

  final String? coverPath;
  final Color tint;
  final Color background;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final path = coverPath ?? '';
    final hasArt = path.isNotEmpty;

    final accentGradient = DecoratedBox(
      key: const ValueKey('accent'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.55],
          colors: [tint, background],
        ),
      ),
      child: const SizedBox.expand(),
    );

    final Widget layer = !hasArt
        ? accentGradient
        : Stack(
            key: ValueKey(path),
            fit: StackFit.expand,
            children: [
              ColoredBox(color: background),
              Opacity(
                opacity: isDark ? 0.55 : 0.4,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48, tileMode: TileMode.clamp),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    cacheWidth: 160, // se desenfoca: no hace falta más resolución
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => accentGradient,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.15, 0.75],
                    colors: [background.withValues(alpha: 0), background],
                  ),
                ),
              ),
            ],
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: layer,
    );
  }
}
