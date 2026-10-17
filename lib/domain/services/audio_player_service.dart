import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/track.dart';
import 'audio_handler_service.dart';

/// 🎵 Servicio de reproducción de audio con integración de notificaciones
class AudioPlayerService {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService._();
    return _instance!;
  }

  AudioPlayerService._();

  MusicAudioHandler? _audioHandler;
  AudioPlayer? _fallbackPlayer; // Reproductor de respaldo
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _useFallback = false;
  MusicAudioHandler? _createdHandler;
  List<Track> _fallbackQueue = [];

  /// Inicializar el servicio de audio
  Future<void> initialize() async {
    // Si ya está inicializado o en proceso de inicialización, no hacer nada
    if (_isInitialized || _isInitializing) {
      debugPrint('⚠️ AudioService ya está ${_isInitialized ? "inicializado" : "inicializando"}');
      return;
    }

    _isInitializing = true;

    try {
      _audioHandler = await AudioService.init(
        builder: () => _createdHandler = MusicAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.musicgamification.music_gamification_app.audio',
          androidNotificationChannelName: 'Reproducción de Música',
          androidNotificationChannelDescription: 'Controles de reproducción de música',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          preloadArtwork: true,
          artDownscaleWidth: 400,
          artDownscaleHeight: 400,
          fastForwardInterval: Duration(seconds: 10),
          rewindInterval: Duration(seconds: 10),
        ),
      );

      _isInitialized = true;
      _useFallback = false;
      debugPrint('✅ AudioPlayerService inicializado con audio_service');
    } catch (e) {
      debugPrint('❌ Error inicializando AudioPlayerService: $e');
      debugPrint('🔄 Usando reproductor de respaldo sin notificaciones');
      // Si el handler llegó a crearse, libera su reproductor: dos AudioPlayer
      // vivos generan estados contradictorios entre el botón y el sonido.
      await _createdHandler?.customAction('dispose');
      _createdHandler = null;
      _fallbackPlayer = AudioPlayer();
      _useFallback = true;
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  MusicAudioHandler? get handler => _audioHandler;
  bool get isServiceInitialized => _audioHandler != null;
  bool get isUsingFallback => _useFallback;

  // Delegación de métodos al handler o fallback
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    debugPrint('🔊 AudioPlayerService.playTracks: ${_useFallback ? "Usando fallback" : "Delegando a handler"}');

    if (_useFallback && _fallbackPlayer != null) {
      await _playTracksFallback(tracks, initialIndex: initialIndex);
    } else if (_audioHandler != null) {
      await handler!.playTracks(tracks, initialIndex: initialIndex);
    } else {
      debugPrint('❌ No hay reproductor disponible');
    }
  }

  Future<void> _playTracksFallback(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty || _fallbackPlayer == null) return;

    debugPrint('🎵 Fallback: Reproduciendo ${tracks[initialIndex].title}');
    _fallbackQueue = tracks;

    try {
      final audioSources = tracks.map((track) {
        return AudioSource.uri(
          Uri.file(track.filePath),
          tag: {'title': track.title, 'artist': track.artist},
        );
      }).toList();

      await _fallbackPlayer!.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );

      unawaited(_fallbackPlayer!.play()); // no bloquear: ver audio_handler_service
      debugPrint('✅ Fallback: Reproducción iniciada');
    } catch (e) {
      debugPrint('❌ Error en fallback: $e');
    }
  }

  Future<void> playTrack(Track track) async {
    debugPrint('🔊 AudioPlayerService.playTrack: ${track.title}');
    await playTracks([track]);
  }

  Future<void> play() async {
    debugPrint('▶️ AudioPlayerService.play()');
    if (_useFallback && _fallbackPlayer != null) {
      unawaited(_fallbackPlayer!.play());
    } else if (_audioHandler != null) {
      await handler!.play();
    }
  }

  Future<void> pause() async {
    debugPrint('⏸️ AudioPlayerService.pause()');
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.pause();
    } else if (_audioHandler != null) {
      await handler!.pause();
    }
  }

  Future<void> stop() async {
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.stop();
    } else if (_audioHandler != null) {
      await handler!.stop();
    }
  }

  Future<void> playPause() async {
    if (_useFallback && _fallbackPlayer != null) {
      if (_fallbackPlayer!.playing) {
        await _fallbackPlayer!.pause();
      } else {
        unawaited(_fallbackPlayer!.play());
      }
    } else if (_audioHandler != null) {
      if (handler!.isPlaying) {
        await pause();
      } else {
        await play();
      }
    }
  }

  Future<void> skipToNext() async {
    if (_useFallback && _fallbackPlayer != null) {
      if (_fallbackPlayer!.hasNext) {
        await _fallbackPlayer!.seekToNext();
      }
    } else if (_audioHandler != null) {
      await handler!.skipToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_useFallback && _fallbackPlayer != null) {
      if (_fallbackPlayer!.hasPrevious) {
        await _fallbackPlayer!.seekToPrevious();
      }
    } else if (_audioHandler != null) {
      await handler!.skipToPrevious();
    }
  }

  Future<void> seek(Duration position) async {
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.seek(position);
    } else if (_audioHandler != null) {
      await handler!.seek(position);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.seek(Duration.zero, index: index);
    } else if (_audioHandler != null) {
      await handler!.skipToQueueItem(index);
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.setLoopMode(mode);
    } else if (_audioHandler != null) {
      final audioServiceMode = switch (mode) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.all => AudioServiceRepeatMode.all,
        LoopMode.one => AudioServiceRepeatMode.one,
      };
      await handler!.setRepeatMode(audioServiceMode);
    }
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    if (_useFallback && _fallbackPlayer != null) {
      await _fallbackPlayer!.setShuffleModeEnabled(enabled);
    } else if (_audioHandler != null) {
      await handler!.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );
    }
  }

  Future<void> addToQueue(Track track) async {
    debugPrint('⚠️ addToQueue no implementado aún');
  }

  // Getters
  Stream<Duration> get positionStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.positionStream;
    }
    return _audioHandler?.positionStream ?? Stream.value(Duration.zero);
  }

  Stream<Duration?> get durationStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.durationStream;
    }
    return _audioHandler?.durationStream ?? Stream.value(null);
  }

  Stream<PlayerState> get playerStateStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.playerStateStream;
    }
    return _audioHandler?.playerStateStream ?? Stream.value(PlayerState(false, ProcessingState.idle));
  }

  Stream<SequenceState?> get sequenceStateStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.sequenceStateStream;
    }
    return _audioHandler?.sequenceStateStream ?? Stream.value(null);
  }

  Stream<LoopMode> get loopModeStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.loopModeStream;
    }
    return _audioHandler?.loopModeStream ?? Stream.value(LoopMode.off);
  }

  Stream<bool> get shuffleModeEnabledStream {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.shuffleModeEnabledStream;
    }
    return _audioHandler?.shuffleModeEnabledStream ?? Stream.value(false);
  }

  PlayerState get playerState {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.playerState;
    }
    return _audioHandler?.player.playerState ?? PlayerState(false, ProcessingState.idle);
  }

  Duration get position {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.position;
    }
    return _audioHandler?.position ?? Duration.zero;
  }

  Duration? get duration {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.duration;
    }
    return _audioHandler?.duration;
  }

  int? get currentIndex {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.currentIndex;
    }
    return _audioHandler?.currentIndex;
  }

  LoopMode get loopMode {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.loopMode;
    }
    return _audioHandler?.loopMode ?? LoopMode.off;
  }

  bool get shuffleModeEnabled {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.shuffleModeEnabled;
    }
    return _audioHandler?.shuffleModeEnabled ?? false;
  }

  List<Track> get currentQueue {
    if (_useFallback) {
      return _fallbackQueue;
    }
    return _audioHandler?.currentQueue ?? [];
  }

  Track? get currentTrack {
    if (_useFallback && _fallbackQueue.isNotEmpty) {
      final idx = currentIndex;
      if (idx != null && idx < _fallbackQueue.length) {
        return _fallbackQueue[idx];
      }
      return null;
    }
    return _audioHandler?.currentTrack;
  }

  bool get isPlaying {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.playing;
    }
    return _audioHandler?.isPlaying ?? false;
  }

  bool get isPaused {
    if (_useFallback && _fallbackPlayer != null) {
      return !_fallbackPlayer!.playing && _fallbackPlayer!.processingState != ProcessingState.idle;
    }
    return _audioHandler != null && !_audioHandler!.isPlaying && _audioHandler!.player.processingState != ProcessingState.idle;
  }

  bool get hasNext {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.hasNext;
    }
    return _audioHandler?.hasNext ?? false;
  }

  bool get hasPrevious {
    if (_useFallback && _fallbackPlayer != null) {
      return _fallbackPlayer!.hasPrevious;
    }
    return _audioHandler?.hasPrevious ?? false;
  }

  double get progress {
    final dur = duration;
    final pos = position;
    if (dur == null || dur.inMilliseconds == 0) return 0.0;
    return pos.inMilliseconds / dur.inMilliseconds;
  }

  /// Liberar recursos
  Future<void> dispose() async {
    if (_fallbackPlayer != null) {
      await _fallbackPlayer!.dispose();
    }
    if (_audioHandler != null) {
      await handler!.customAction('dispose');
    }
    _isInitialized = false;
  }
}

