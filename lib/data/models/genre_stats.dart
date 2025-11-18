import 'package:equatable/equatable.dart';

/// Modelo de estadísticas por género
class GenreStats extends Equatable {
  final int? id;
  final String genre;
  final int totalListeningMs;

  const GenreStats({
    this.id,
    required this.genre,
    this.totalListeningMs = 0,
  });

  /// Tiempo en horas
  double get totalListeningHours => totalListeningMs / (1000 * 60 * 60);

  /// Copia con modificaciones
  GenreStats copyWith({
    int? id,
    String? genre,
    int? totalListeningMs,
  }) {
    return GenreStats(
      id: id ?? this.id,
      genre: genre ?? this.genre,
      totalListeningMs: totalListeningMs ?? this.totalListeningMs,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'genre': genre,
      'totalListeningMs': totalListeningMs,
    };
  }

  /// Crear desde Map
  factory GenreStats.fromMap(Map<String, dynamic> map) {
    return GenreStats(
      id: map['id'] as int?,
      genre: map['genre'] as String,
      totalListeningMs: map['totalListeningMs'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, genre, totalListeningMs];

  @override
  String toString() {
    return 'GenreStats(genre: $genre, hours: ${totalListeningHours.toStringAsFixed(1)})';
  }
}
