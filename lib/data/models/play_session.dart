import 'package:equatable/equatable.dart';
import '../../domain/enums/playback_source.dart';

/// Modelo de una sesión de reproducción
class PlaySession extends Equatable {
  final int? id;
  final int trackId;
  final DateTime startTime;
  final DateTime endTime;
  final int playedMs;
  final bool skipped;
  final int? skipPositionMs;
  final PlaybackSource source;

  const PlaySession({
    this.id,
    required this.trackId,
    required this.startTime,
    required this.endTime,
    required this.playedMs,
    required this.skipped,
    this.skipPositionMs,
    required this.source,
  });

  /// Constructor para crear una sesión en progreso
  factory PlaySession.inProgress({
    required int trackId,
    required PlaybackSource source,
  }) {
    final now = DateTime.now();
    return PlaySession(
      trackId: trackId,
      startTime: now,
      endTime: now,
      playedMs: 0,
      skipped: false,
      source: source,
    );
  }

  /// Copia con modificaciones
  PlaySession copyWith({
    int? id,
    int? trackId,
    DateTime? startTime,
    DateTime? endTime,
    int? playedMs,
    bool? skipped,
    int? skipPositionMs,
    PlaybackSource? source,
  }) {
    return PlaySession(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      playedMs: playedMs ?? this.playedMs,
      skipped: skipped ?? this.skipped,
      skipPositionMs: skipPositionMs ?? this.skipPositionMs,
      source: source ?? this.source,
    );
  }

  /// Calcular duración de la sesión
  Duration get duration => endTime.difference(startTime);

  /// Verificar si la sesión fue completada (más del 80% reproducido)
  bool wasCompleted(int totalDurationMs) {
    if (totalDurationMs <= 0) return false;
    return playedMs >= (totalDurationMs * 0.8);
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackId': trackId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'playedMs': playedMs,
      'skipped': skipped ? 1 : 0,
      'skipPositionMs': skipPositionMs,
      'source': source.name,
    };
  }

  /// Crear desde Map
  factory PlaySession.fromMap(Map<String, dynamic> map) {
    return PlaySession(
      id: map['id'] as int?,
      trackId: map['trackId'] as int,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      playedMs: map['playedMs'] as int,
      skipped: (map['skipped'] as int) == 1,
      skipPositionMs: map['skipPositionMs'] as int?,
      source: PlaybackSource.values.firstWhere(
            (e) => e.name == map['source'],
        orElse: () => PlaybackSource.manual,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    trackId,
    startTime,
    endTime,
    playedMs,
    skipped,
    skipPositionMs,
    source,
  ];

  @override
  String toString() {
    return 'PlaySession(id: $id, trackId: $trackId, playedMs: $playedMs, skipped: $skipped)';
  }
}
