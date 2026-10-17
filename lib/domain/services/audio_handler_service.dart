import 'package:flutter/foundation.dart' show debugPrint;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/track.dart';
import 'dart:async' show unawaited;
import 'dart:io';

/// 🎵 Handler de audio para integración con notificaciones del sistema
class MusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  List<Track> _currentQueue = [];

  MusicAudioHandler() {
    debugPrint('🎧 Inicializando MusicAudioHandler...');
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('🎧 Configurando AudioPlayer...');

      // Sincronizar estado del player con el sistema
      _player.playbackEventStream.listen(_broadcastState);
      debugPrint('✅ PlaybackEventStream conectado');

      // Sincronizar cambios de track
      _player.sequenceStateStream.listen((state) {
        final currentIndex = state.currentIndex;
        if (currentIndex != null && currentIndex < _currentQueue.length) {
          final track = _currentQueue[currentIndex];
          debugPrint('🎵 Track actual: ${track.title}');
          mediaItem.add(_trackToMediaItem(track));
        }
      });
      debugPrint('✅ SequenceStateStream conectado');

      debugPrint('✅ MusicAudioHandler inicializado correctamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando MusicAudioHandler: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Convertir Track a MediaItem para las notificaciones
  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.id.toString(),
      album: track.album,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.durationMs),
      artUri: track.coverArtPath != null && File(track.coverArtPath!).existsSync()
          ? Uri.file(track.coverArtPath!)
          : null,
    );
  }

  /// Reproducir una lista de tracks
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) {
      debugPrint('⚠️ playTracks: Lista de tracks vacía');
      return;
    }

    debugPrint('🎵 playTracks: Iniciando con ${tracks.length} tracks, index: $initialIndex');
    _currentQueue = tracks;

    try {
      // Validar que el track inicial existe
      final initialTrack = tracks[initialIndex];
      final initialFile = File(initialTrack.filePath);
      if (!initialFile.existsSync()) {
        debugPrint('❌ ERROR: El archivo del track inicial no existe: ${initialTrack.filePath}');
        throw Exception('El archivo de audio no existe: ${initialTrack.title}');
      }

      final audioSources = <AudioSource>[];
      final validIndices = <int>[];

      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final file = File(track.filePath);
        final exists = file.existsSync();

        debugPrint('📁 [$i] ${track.title}');
        debugPrint('   Path: ${track.filePath}');
        debugPrint('   Existe: $exists');

        if (!exists) {
          debugPrint('   ⚠️ Archivo no encontrado, omitiendo...');
          continue;
        }

        try {
          final source = AudioSource.uri(
            Uri.file(track.filePath),
            tag: _trackToMediaItem(track),
          );
          audioSources.add(source);
          validIndices.add(i);
        } catch (e) {
          debugPrint('   ❌ Error creando AudioSource: $e');
        }
      }

      if (audioSources.isEmpty) {
        debugPrint('❌ No hay fuentes de audio válidas para reproducir');
        throw Exception('No se encontraron archivos de audio válidos');
      }

      // Calcular el nuevo índice basado en los tracks válidos
      final newInitialIndex = validIndices.indexOf(initialIndex);
      if (newInitialIndex == -1) {
        debugPrint('⚠️ El track inicial no está en los válidos, usando índice 0');
      }
      final finalIndex = newInitialIndex != -1 ? newInitialIndex : 0;

      // Establecer la cola en el sistema (solo tracks válidos)
      final validTracks = validIndices.map((i) => tracks[i]).toList();
      queue.add(validTracks.map((t) => _trackToMediaItem(t)).toList());
      _currentQueue = validTracks;

      // Usar la nueva API de just_audio
      debugPrint('🎯 Configurando ${audioSources.length} audio sources, índice: $finalIndex');
      await _player.setAudioSources(
        audioSources,
        initialIndex: finalIndex,
        initialPosition: Duration.zero,
      );

      debugPrint('🎯 Iniciando reproducción...');
      // No se hace await: el Future de play() de just_audio solo termina al
      // pausar o al acabar la canción, y bloquearía el flujo de estado.
      unawaited(_player.play());
      debugPrint('✅ Reproducción iniciada');
    } catch (e, stackTrace) {
      debugPrint('❌ Error en playTracks: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    // Sin await (ver playTracks): el Future de just_audio dura hasta la pausa.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// La app no tiene velocidad variable: si el sistema (controles de medios)
  /// pide otra velocidad, se ignora y la reproducción se mantiene a 1x.
  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(AppConstants.defaultPlaybackSpeed);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _currentQueue.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));

    await _player.setLoopMode(
      repeatMode == AudioServiceRepeatMode.all
          ? LoopMode.all
          : repeatMode == AudioServiceRepeatMode.one
              ? LoopMode.one
              : LoopMode.off,
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));

    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  /// Broadcast del estado actual
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  // Getters para compatibilidad
  AudioPlayer get player => _player;
  List<Track> get currentQueue => _currentQueue;

  Track? get currentTrack {
    final index = _player.currentIndex;
    if (index != null && index < _currentQueue.length) {
      return _currentQueue[index];
    }
    return null;
  }

  // Streams públicos para compatibilidad
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  // Estado actual
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  int? get currentIndex => _player.currentIndex;
  LoopMode get loopMode => _player.loopMode;
  bool get shuffleModeEnabled => _player.shuffleModeEnabled;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
    }
  }
}

