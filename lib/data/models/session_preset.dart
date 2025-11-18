import 'package:equatable/equatable.dart';

/// Modelo de una sesión guardada (gym, estudio, etc.)
class SessionPreset extends Equatable {
  final int? id;
  final String name;
  final String type; // gym, estudio, chill, etc.
  final List<int> trackIds;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const SessionPreset({
    this.id,
    required this.name,
    required this.type,
    required this.trackIds,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Constructor para crear sesión vacía
  factory SessionPreset.empty(String name, String type) {
    return SessionPreset(
      name: name,
      type: type,
      trackIds: [],
      createdAt: DateTime.now(),
    );
  }

  /// Cantidad de tracks
  int get trackCount => trackIds.length;

  /// Copia con modificaciones
  SessionPreset copyWith({
    int? id,
    String? name,
    String? type,
    List<int>? trackIds,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return SessionPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'trackIds': trackIds.join(','), // Guardar como string separado por comas
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// Crear desde Map
  factory SessionPreset.fromMap(Map<String, dynamic> map) {
    return SessionPreset(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      trackIds: (map['trackIds'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    trackIds,
    createdAt,
    lastUsedAt,
  ];

  @override
  String toString() {
    return 'SessionPreset(name: $name, type: $type, tracks: ${trackIds.length})';
  }
}
