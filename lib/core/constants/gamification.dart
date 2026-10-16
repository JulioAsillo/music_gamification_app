/// Reglas de gamificación compartidas entre la lógica y la UI.
abstract final class Gamification {
  /// XP por cada canción que cuenta como escuchada.
  static const xpPerSong = 12;

  /// Una canción cuenta como escuchada al llegar a este porcentaje…
  static const countAtFraction = 0.3;

  /// …o a estos segundos, lo que ocurra primero (para canciones largas).
  static const countAtSeconds = 30;

  /// Nivel a partir del XP total: `nivel = ⌊√(XP / 1000)⌋ + 1`
  /// (misma fórmula que `StatsDao.addXP`).
  static int levelForXp(int xp) {
    var level = 1;
    while (xpToReach(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  /// XP total necesario para llegar a [level]: `(nivel - 1)² × 1000`.
  static int xpToReach(int level) => (level - 1) * (level - 1) * 1000;
}
