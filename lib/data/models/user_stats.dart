import 'dart:math';

import 'package:equatable/equatable.dart';

/// Modelo de estadísticas globales del usuario
class UserStats extends Equatable {
  final int id; // Siempre será 1 (única fila)
  final int totalListeningMs;
  final int totalTracksPlayed;
  final int currentStreakDays;
  final DateTime lastListeningDate;
  final int level;
  final int totalXP;

  const UserStats({
    this.id = 1,
    this.totalListeningMs = 0,
    this.totalTracksPlayed = 0,
    this.currentStreakDays = 0,
    required this.lastListeningDate,
    this.level = 1,
    this.totalXP = 0,
  });

  /// Constructor con valores por defecto
  factory UserStats.initial() {
    return UserStats(
      lastListeningDate: DateTime.now(),
    );
  }

  /// Tiempo total en horas
  double get totalListeningHours => totalListeningMs / (1000 * 60 * 60);

  /// Calcular nivel basado en XP
  /// Fórmula: nivel = sqrt(XP / 1000)
  int calculateLevel(int xp) {
    return sqrt(xp / 1000).floor() + 1;
  }

  /// XP necesario para siguiente nivel
  int get xpForNextLevel {
    final nextLevel = level + 1;
    return (nextLevel * nextLevel * 1000) - totalXP;
  }

  /// Progreso al siguiente nivel (0.0 a 1.0)
  double get levelProgress {
    final currentLevelXP = level * level * 1000;
    final nextLevelXP = (level + 1) * (level + 1) * 1000;
    final xpInCurrentLevel = totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;
    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Copia con modificaciones
  UserStats copyWith({
    int? id,
    int? totalListeningMs,
    int? totalTracksPlayed,
    int? currentStreakDays,
    DateTime? lastListeningDate,
    int? level,
    int? totalXP,
  }) {
    return UserStats(
      id: id ?? this.id,
      totalListeningMs: totalListeningMs ?? this.totalListeningMs,
      totalTracksPlayed: totalTracksPlayed ?? this.totalTracksPlayed,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      lastListeningDate: lastListeningDate ?? this.lastListeningDate,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalListeningMs': totalListeningMs,
      'totalTracksPlayed': totalTracksPlayed,
      'currentStreakDays': currentStreakDays,
      'lastListeningDate': lastListeningDate.toIso8601String(),
      'level': level,
      'totalXP': totalXP,
    };
  }

  /// Crear desde Map
  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'] as int? ?? 1,
      totalListeningMs: map['totalListeningMs'] as int? ?? 0,
      totalTracksPlayed: map['totalTracksPlayed'] as int? ?? 0,
      currentStreakDays: map['currentStreakDays'] as int? ?? 0,
      lastListeningDate: DateTime.parse(map['lastListeningDate'] as String),
      level: map['level'] as int? ?? 1,
      totalXP: map['totalXP'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    totalListeningMs,
    totalTracksPlayed,
    currentStreakDays,
    lastListeningDate,
    level,
    totalXP,
  ];

  @override
  String toString() {
    return 'UserStats(level: $level, XP: $totalXP, streak: $currentStreakDays days)';
  }
}
