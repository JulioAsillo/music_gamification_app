import 'package:equatable/equatable.dart';
import '../../domain/enums/achievement_type.dart';
import '../../domain/enums/achievement_status.dart';

/// Modelo de un logro
class Achievement extends Equatable {
  final String id; // ID único del logro (ej: "streak_7_days")
  final String title;
  final String description;
  final AchievementType type;
  final AchievementStatus status;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = AchievementStatus.locked,
    this.unlockedAt,
    this.currentProgress = 0,
    required this.targetProgress,
    this.xpReward = 100,
  });

  /// Progreso como porcentaje (0.0 a 1.0)
  double get progressPercentage {
    if (targetProgress <= 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  /// Verificar si está completado
  bool get isCompleted => currentProgress >= targetProgress;

  /// Copia con modificaciones
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    AchievementStatus? status,
    DateTime? unlockedAt,
    int? currentProgress,
    int? targetProgress,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  /// Convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'xpReward': xpReward,
    };
  }

  /// Crear desde Map
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: AchievementType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => AchievementType.special,
      ),
      status: AchievementStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => AchievementStatus.locked,
      ),
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
      currentProgress: map['currentProgress'] as int? ?? 0,
      targetProgress: map['targetProgress'] as int,
      xpReward: map['xpReward'] as int? ?? 100,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    status,
    unlockedAt,
    currentProgress,
    targetProgress,
    xpReward,
  ];

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, progress: $currentProgress/$targetProgress, status: $status)';
  }
}
