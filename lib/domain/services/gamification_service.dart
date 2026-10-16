import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/constants/gamification.dart';
import '../../data/database/app_database.dart';
import '../../data/models/track.dart';
import '../enums/achievement_status.dart';
import '../enums/achievement_type.dart';

/// Evento para mostrar feedback en la UI ("+12 XP", "Logro desbloqueado").
sealed class GamificationEvent {
  const GamificationEvent();
}

class XpGained extends GamificationEvent {
  const XpGained(this.xp, this.trackTitle);
  final int xp;
  final String trackTitle;
}

class AchievementUnlocked extends GamificationEvent {
  const AchievementUnlocked(this.title, this.xp);
  final String title;
  final int xp;
}

class LevelUp extends GamificationEvent {
  const LevelUp(this.level);
  final int level;
}

/// Lógica de gamificación: sesiones de escucha, tiempo, racha, XP, nivel y logros.
///
/// Antes esto estaba como TODO en `MusicPlayerNotifier._updatePlaybackStats`.
/// Las operaciones se ejecutan en serie para que dos actualizaciones
/// simultáneas (p. ej. fin de canción + guardado periódico) no se pisen.
class GamificationService {
  GamificationService(this._db) {
    _serial(_seedAchievements);
  }

  final AppDatabase _db;
  final _events = StreamController<GamificationEvent>.broadcast();
  Future<void> _queue = Future.value();

  Stream<GamificationEvent> get events => _events.stream;

  void dispose() => _events.close();

  Future<T> _serial<T>(Future<T> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  void _emit(GamificationEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  // ───────────────────────── Logros ─────────────────────────

  static const _defs = <_AchievementDef>[
    _AchievementDef('first_song', 'Primera canción', 'Reproduce tu primera canción', AchievementType.songCount, 1, 50),
    _AchievementDef('marathon_10h', 'Maratonista', 'Escucha 10 horas de música', AchievementType.totalTime, 600, 200),
    _AchievementDef('streak_7', 'Racha de 7 días', 'Escucha música 7 días seguidos', AchievementType.streak, 7, 300),
    _AchievementDef('explorer_5', 'Explorador', 'Escucha 5 géneros distintos', AchievementType.exploration, 5, 150),
    _AchievementDef('artists_20', 'Ecléctico', 'Escucha a 20 artistas distintos', AchievementType.artistDiversity, 20, 250),
    _AchievementDef('night_owl', 'Búho nocturno', 'Escucha música entre medianoche y las 5 a. m.', AchievementType.nightOwl, 1, 100),
    _AchievementDef('collector_1000', 'Coleccionista', 'Reproduce 1000 canciones', AchievementType.songCount, 1000, 500),
    _AchievementDef('streak_30', 'Imparable', 'Mantén una racha de 30 días', AchievementType.streak, 30, 1000),
  ];

  /// Crea los logros por defecto si no existen (no toca el progreso guardado).
  Future<void> _seedAchievements() async {
    await _db.batch((b) {
      for (final d in _defs) {
        b.insert(
          _db.achievementsTable,
          AchievementsTableCompanion.insert(
            id: d.id,
            title: d.title,
            description: d.description,
            type: d.type.name,
            status: AchievementStatus.locked.name,
            targetProgress: d.target,
            xpReward: Value(d.xp),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Actualiza el progreso de un logro; si se completa lo desbloquea
  /// y devuelve el XP de recompensa (0 si no se desbloqueó ahora).
  Future<int> _setProgress(String id, int value) async {
    final row = await (_db.select(_db.achievementsTable)..where((a) => a.id.equals(id))).getSingleOrNull();
    if (row == null || row.status == AchievementStatus.unlocked.name) return 0;

    final progress = value.clamp(0, row.targetProgress);
    if (progress == row.currentProgress) return 0;

    final completed = progress >= row.targetProgress;
    await (_db.update(_db.achievementsTable)..where((a) => a.id.equals(id))).write(
      AchievementsTableCompanion(
        currentProgress: Value(progress),
        status: Value(completed
            ? AchievementStatus.unlocked.name
            : progress > 0
                ? AchievementStatus.inProgress.name
                : AchievementStatus.locked.name),
        unlockedAt: completed ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
    if (!completed) return 0;
    _emit(AchievementUnlocked(row.title, row.xpReward));
    return row.xpReward;
  }

  // ───────────────────────── Estadísticas ─────────────────────────

  Future<UserStatsTableData> _stats() async {
    final row = await (_db.select(_db.userStatsTable)..where((s) => s.id.equals(1))).getSingleOrNull();
    if (row != null) return row;
    await _db.into(_db.userStatsTable).insert(
          UserStatsTableCompanion.insert(lastListeningDate: DateTime.now()),
          mode: InsertMode.insertOrIgnore,
        );
    return (_db.select(_db.userStatsTable)..where((s) => s.id.equals(1))).getSingle();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Racha: +1 si la última escucha fue ayer, igual si fue hoy, 1 si hubo un hueco.
  static int _nextStreak(UserStatsTableData s, DateTime now) {
    if (s.currentStreakDays <= 0) return 1;
    final gap = _day(now).difference(_day(s.lastListeningDate)).inDays;
    if (gap <= 0) return s.currentStreakDays;
    if (gap == 1) return s.currentStreakDays + 1;
    return 1;
  }

  Future<void> _addXp(UserStatsTableData before, int xp) async {
    if (xp <= 0) return;
    final current = await _stats();
    final total = current.totalXP + xp;
    final level = Gamification.levelForXp(total);
    await (_db.update(_db.userStatsTable)..where((s) => s.id.equals(1))).write(
      UserStatsTableCompanion(totalXP: Value(total), level: Value(level)),
    );
    if (level > before.level) _emit(LevelUp(level));
  }

  /// Registra un tramo de escucha real de [track] entre [start] y [end]:
  /// sesión, tiempo total, tiempo por género, racha y logros de tiempo/racha.
  Future<void> recordListening(Track track, DateTime start, DateTime end) => _serial(() async {
        final ms = end.difference(start).inMilliseconds;
        if (ms < 1000 || track.id == null) return;

        await _db.into(_db.playSessionsTable).insert(
              PlaySessionsTableCompanion.insert(
                trackId: track.id!,
                startTime: start,
                endTime: end,
                playedMs: ms,
                source: 'manual',
              ),
            );

        final s = await _stats();
        final streak = _nextStreak(s, end);
        await (_db.update(_db.userStatsTable)..where((r) => r.id.equals(1))).write(
          UserStatsTableCompanion(
            totalListeningMs: Value(s.totalListeningMs + ms),
            currentStreakDays: Value(streak),
            lastListeningDate: Value(end),
          ),
        );

        final genre = track.genre.trim();
        if (genre.isNotEmpty && genre.toLowerCase() != 'unknown' && genre.toLowerCase() != 'desconocido') {
          await _db.customStatement(
            'INSERT INTO genre_stats (genre, total_listening_ms) VALUES (?, ?) '
            'ON CONFLICT(genre) DO UPDATE SET total_listening_ms = total_listening_ms + excluded.total_listening_ms',
            [genre, ms],
          );
          // customStatement no avisa a los streams: notificar a mano
          _db.notifyUpdates({TableUpdate.onTable(_db.genreStatsTable, kind: UpdateKind.update)});
        }

        final genreCount = _db.genreStatsTable.id.count();
        final genres = await (_db.selectOnly(_db.genreStatsTable)..addColumns([genreCount]))
            .map((r) => r.read(genreCount) ?? 0)
            .getSingle();

        var xp = 0;
        xp += await _setProgress('marathon_10h', (s.totalListeningMs + ms) ~/ 60000);
        xp += await _setProgress('streak_7', streak);
        xp += await _setProgress('streak_30', streak);
        xp += await _setProgress('explorer_5', genres);
        if (start.hour < 5) xp += await _setProgress('night_owl', 1);
        await _addXp(s, xp);
      });

  /// Una canción llegó al umbral de "escuchada": +XP, contador y logros de cantidad.
  Future<void> recordCountedPlay(Track track) => _serial(() async {
        final s = await _stats();
        final played = s.totalTracksPlayed + 1;
        await (_db.update(_db.userStatsTable)..where((r) => r.id.equals(1))).write(
          UserStatsTableCompanion(totalTracksPlayed: Value(played)),
        );

        final artists = await (_db.selectOnly(_db.tracksTable, distinct: true)
              ..addColumns([_db.tracksTable.artist])
              ..where(_db.tracksTable.playCount.isBiggerThanValue(0)))
            .get();

        var xp = Gamification.xpPerSong;
        xp += await _setProgress('first_song', played);
        xp += await _setProgress('collector_1000', played);
        xp += await _setProgress('artists_20', artists.length);
        await _addXp(s, xp);
        _emit(XpGained(Gamification.xpPerSong, track.title));
      });
}

class _AchievementDef {
  const _AchievementDef(this.id, this.title, this.description, this.type, this.target, this.xp);
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final int xp;
}
