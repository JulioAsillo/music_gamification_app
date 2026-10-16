import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Riverpod 3: StateProvider/StateNotifier viven aquí
import 'package:just_audio/just_audio.dart';
import '../../data/models/track.dart';
import '../../domain/services/audio_player_service.dart';
import 'database_provider.dart';

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

  Timer? _playbackTimer;
  DateTime? _trackStartTime;
  bool _trackCountedAsPlayed = false;

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
      if (isPlaying && _trackStartTime == null) {
        _startPlaybackTracking();
      } else if (!isPlaying && _trackStartTime != null) {
        _pausePlaybackTracking();
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

        // Si cambió el track, registrar la reproducción anterior
        if (state.currentTrack != null &&
            currentTrack != null &&
            state.currentTrack!.id != currentTrack.id) {
          _onTrackChanged();
        }

        state = state.copyWith(
          currentTrack: currentTrack,
          queue: queue,
          currentIndex: currentIndex,
        );

        // Iniciar tracking del nuevo track
        if (currentTrack != null) {
          _trackStartTime = DateTime.now();
          _trackCountedAsPlayed = false;
        }
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

      _trackStartTime = DateTime.now();
      _trackCountedAsPlayed = false;

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
    if (state.currentTrack == null || _trackCountedAsPlayed) return;

    final duration = state.duration;
    if (duration == null || duration.inSeconds == 0) return;

    // Contar como reproducido si llegó al 30% o 30 segundos
    final threshold = duration.inSeconds > 100 ? duration.inSeconds * 0.3 : 30;

    if (position.inSeconds >= threshold) {
      _trackCountedAsPlayed = true;
      _registerPlayback();
    }
  }

  /// Iniciar tracking de reproducción
  void _startPlaybackTracking() {
    _trackStartTime = DateTime.now();
    _playbackTimer?.cancel();

    // Timer para actualizar estadísticas cada minuto
    _playbackTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updatePlaybackStats();
    });
  }

  /// Pausar tracking
  void _pausePlaybackTracking() {
    _playbackTimer?.cancel();
    _updatePlaybackStats();
  }

  /// Cuando cambia de track
  void _onTrackChanged() {
    _updatePlaybackStats();
    _trackStartTime = DateTime.now();
    _trackCountedAsPlayed = false;
  }

  /// Cuando termina el track
  void _onTrackCompleted() {
    if (!_trackCountedAsPlayed) {
      _trackCountedAsPlayed = true;
      _registerPlayback();
    }
    _updatePlaybackStats();
  }

  /// Registrar reproducción en la base de datos
  Future<void> _registerPlayback() async {
    final track = state.currentTrack;
    if (track == null) return;

    try {
      final database = _ref.read(appDatabaseProvider);

      // Incrementar play count
      await database.tracksDao.incrementPlayCount(track.id!);

      print('✅ Reproducción registrada: ${track.title}');
    } catch (e) {
      print('❌ Error registrando reproducción: $e');
    }
  }

  /// Actualizar estadísticas de reproducción
  Future<void> _updatePlaybackStats() async {
    if (_trackStartTime == null || state.currentTrack == null) return;

    try {
      final playTime = DateTime.now().difference(_trackStartTime!);

      // TODO: Registrar sesión de reproducción en play_sessions
      // TODO: Actualizar estadísticas de usuario
      // TODO: Actualizar estadísticas de género

      print('📊 Tiempo de reproducción: ${playTime.inSeconds}s');
    } catch (e) {
      print('❌ Error actualizando estadísticas: $e');
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
    _playbackTimer?.cancel();
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

