import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Riverpod 3: StateProvider/StateNotifier viven aquí
import 'package:just_audio/just_audio.dart';
import '../../core/constants/gamification.dart';
import '../../data/models/track.dart';
import '../../domain/services/audio_player_service.dart';
import 'database_provider.dart';
import 'gamification_provider.dart';

/// 🎵 Estado del reproductor
class PlayerState {
  final Track? currentTrack;
  final List<Track> queue;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final bool isLoading;
  final LoopMode loopMode;
  final bool shuffleEnabled;
  final int? currentIndex;

  PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.position = Duration.zero,
    this.duration,
    this.isPlaying = false,
    this.isLoading = false,
    this.loopMode = LoopMode.off,
    this.shuffleEnabled = false,
    this.currentIndex,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    LoopMode? loopMode,
    bool? shuffleEnabled,
    int? currentIndex,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      loopMode: loopMode ?? this.loopMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }

  bool get hasNext => currentIndex != null && currentIndex! < queue.length - 1;
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;
}

/// 📦 Notifier del reproductor
class MusicPlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayerService _audioService;
  final Ref _ref;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceStateSubscription;
  StreamSubscription? _loopModeSubscription;
  StreamSubscription? _shuffleSubscription;

  // ── Seguimiento de escucha para la gamificación ──
  // Un "tramo" es tiempo continuo sonando de una misma canción. Se guarda
  // al pausar, al cambiar de canción y cada 30 s (por si la app se cierra).
  Timer? _flushTimer;
  DateTime? _segmentStart;
  Track? _segmentTrack;
  bool _trackCountedAsPlayed = false;
  int _lastPositionSec = 0;

  MusicPlayerNotifier(this._audioService, this._ref) : super(PlayerState()) {
    _setupListeners();
  }

  /// Configurar listeners de los streams
  void _setupListeners() {
    // Listener de posición
    _positionSubscription = _audioService.positionStream.listen((position) {
      state = state.copyWith(position: position);
      _checkPlaybackProgress(position);
    });

    // Listener de duración
    _durationSubscription = _audioService.durationStream.listen((duration) {
      state = state.copyWith(duration: duration);
    });

    // Listener de estado del player
    _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final isLoading = playerState.processingState == ProcessingState.loading ||
                        playerState.processingState == ProcessingState.buffering;

      state = state.copyWith(
        isPlaying: isPlaying,
        isLoading: isLoading,
      );

      // Gestionar inicio/pausa de reproducción
      final completed = playerState.processingState == ProcessingState.completed;
      if (isPlaying && !completed && _segmentStart == null) {
        _startSegment();
      } else if ((!isPlaying || completed) && _segmentStart != null) {
        _endSegment();
      }

      // Detectar fin de track
      if (playerState.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // Listener de secuencia (cambio de track)
    _sequenceStateSubscription = _audioService.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        final currentIndex = sequenceState.currentIndex;
        final queue = _audioService.currentQueue;

        final currentTrack = currentIndex != null && currentIndex < queue.length
            ? queue[currentIndex]
            : null;

        // Si cambió el track, cerrar el tramo del anterior
        if (currentTrack != null && currentTrack.id != _segmentTrack?.id) {
          _switchTrack(currentTrack);
        }

        state = state.copyWith(
          currentTrack: currentTrack,
          queue: queue,
          currentIndex: currentIndex,
        );
      }
    });

    // Listener de loop mode
    _loopModeSubscription = _audioService.loopModeStream.listen((loopMode) {
      state = state.copyWith(loopMode: loopMode);
    });

    // Listener de shuffle
    _shuffleSubscription = _audioService.shuffleModeEnabledStream.listen((enabled) {
      state = state.copyWith(shuffleEnabled: enabled);
    });
  }

  /// Reproducir una lista de tracks
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) {
      print('⚠️ MusicPlayerNotifier.playTracks: Lista vacía');
      return;
    }

    print('🎵 MusicPlayerNotifier.playTracks: Iniciando reproducción de ${tracks[initialIndex].title}');
    print('   Total de tracks: ${tracks.length}, índice inicial: $initialIndex');
    print('   Path del archivo: ${tracks[initialIndex].filePath}');
    state = state.copyWith(isLoading: true);

    try {
      print('🔄 Llamando a _audioService.playTracks...');
      await _audioService.playTracks(tracks, initialIndex: initialIndex);

      // Esperar un momento para que el estado se actualice
      await Future.delayed(const Duration(milliseconds: 100));

      state = state.copyWith(
        currentTrack: tracks[initialIndex],
        queue: tracks,
        currentIndex: initialIndex,
        isLoading: false,
        isPlaying: true,
      );

      // Nueva reproducción explícita: cuenta de nuevo aunque sea la misma canción
      _switchTrack(tracks[initialIndex]);

      print('✅ Estado actualizado - Reproduciendo: ${tracks[initialIndex].title}');
    } catch (e) {
      print('❌ Error en playTracks: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reproducir un track individual
  Future<void> playTrack(Track track) async {
    await playTracks([track]);
  }

  /// Play/Pause
  Future<void> playPause() async {
    // Actualizar estado inmediatamente para feedback visual rápido
    final willPlay = !state.isPlaying;
    state = state.copyWith(isPlaying: willPlay);

    await _audioService.playPause();
  }

  /// Siguiente track
  Future<void> skipToNext() async {
    // Si está en modo repetir una, temporalmente cambiar a off para permitir el cambio
    final originalLoopMode = state.loopMode;
    if (originalLoopMode == LoopMode.one) {
      await _audioService.setLoopMode(LoopMode.off);
    }

    await _audioService.skipToNext();

    // Restaurar el modo de repetición después de cambiar
    if (originalLoopMode == LoopMode.one) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioService.setLoopMode(LoopMode.one);
    }
  }

  /// Track anterior
  Future<void> skipToPrevious() async {
    // Si está en modo repetir una, temporalmente cambiar a off para permitir el cambio
    final originalLoopMode = state.loopMode;
    if (originalLoopMode == LoopMode.one) {
      await _audioService.setLoopMode(LoopMode.off);
    }

    await _audioService.skipToPrevious();

    // Restaurar el modo de repetición después de cambiar
    if (originalLoopMode == LoopMode.one) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioService.setLoopMode(LoopMode.one);
    }
  }

  /// Buscar posición
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Cambiar loop mode
  Future<void> toggleLoopMode() async {
    final newMode = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _audioService.setLoopMode(newMode);
  }

  /// Cambiar shuffle
  Future<void> toggleShuffle() async {
    await _audioService.setShuffleModeEnabled(!state.shuffleEnabled);
  }

  /// Agregar a la cola
  Future<void> addToQueue(Track track) async {
    await _audioService.addToQueue(track);
    state = state.copyWith(queue: _audioService.currentQueue);
  }

  /// Saltar a un índice
  Future<void> skipToIndex(int index) async {
    await _audioService.skipToIndex(index);
  }

  /// Verificar progreso para registrar reproducción
  void _checkPlaybackProgress(Duration position) {
    // Repetir una canción (o volver al inicio) permite contarla otra vez
    if (position.inSeconds < 2 && _lastPositionSec > 10) {
      _trackCountedAsPlayed = false;
    }
    _lastPositionSec = position.inSeconds;

    if (state.currentTrack == null || _trackCountedAsPlayed) return;

    final duration = state.duration;
    if (duration == null || duration.inSeconds == 0) return;

    // Contar como reproducido al llegar al 30 % o a los 30 s (lo que ocurra primero)
    final threshold = Gamification.countAtFraction * duration.inSeconds < Gamification.countAtSeconds
        ? Gamification.countAtFraction * duration.inSeconds
        : Gamification.countAtSeconds.toDouble();

    if (position.inSeconds >= threshold) {
      _trackCountedAsPlayed = true;
      _registerPlayback();
    }
  }

  void _startSegment() {
    _segmentStart = DateTime.now();
    _segmentTrack ??= state.currentTrack;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flushSegment(keepRunning: true));
  }

  void _endSegment() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushSegment(keepRunning: false);
  }

  /// Guarda el tiempo escuchado desde el inicio del tramo.
  void _flushSegment({required bool keepRunning}) {
    final start = _segmentStart;
    final track = _segmentTrack;
    final now = DateTime.now();
    if (start != null && track != null) {
      try {
        _ref.read(gamificationServiceProvider).recordListening(track, start, now).catchError((Object e) {
          print('❌ Error guardando escucha: $e');
        });
      } catch (_) {
        // El provider ya se destruyó (cierre de la app): no hay dónde guardar.
      }
    }
    _segmentStart = keepRunning ? now : null;
  }

  /// Cierra el tramo de la canción anterior y empieza a seguir [next].
  void _switchTrack(Track? next) {
    _flushSegment(keepRunning: _segmentStart != null);
    _segmentTrack = next;
    _trackCountedAsPlayed = false;
    _lastPositionSec = 0;
  }

  /// Cuando termina la cola
  void _onTrackCompleted() {
    if (!_trackCountedAsPlayed && state.currentTrack != null) {
      _trackCountedAsPlayed = true;
      _registerPlayback();
    }
  }

  /// Registrar reproducción: contador de la canción + XP y logros
  Future<void> _registerPlayback() async {
    final track = _segmentTrack ?? state.currentTrack;
    if (track == null || track.id == null) return;

    try {
      final database = _ref.read(appDatabaseProvider);
      await database.tracksDao.incrementPlayCount(track.id!);
      await _ref.read(gamificationServiceProvider).recordCountedPlay(track);
    } catch (e) {
      print('❌ Error registrando reproducción: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
    _loopModeSubscription?.cancel();
    _shuffleSubscription?.cancel();
    _flushTimer?.cancel();
    _flushSegment(keepRunning: false);
    super.dispose();
  }
}

/// Provider del reproductor de música
final musicPlayerProvider = StateNotifierProvider<MusicPlayerNotifier, PlayerState>((ref) {
  final audioService = AudioPlayerService.instance;
  return MusicPlayerNotifier(audioService, ref);
});

/// Provider para verificar si hay música reproduciéndose
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(musicPlayerProvider).isPlaying;
});

/// Provider del track actual
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(musicPlayerProvider).currentTrack;
});

