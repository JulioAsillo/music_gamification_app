import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import 'app_card.dart';
import 'xp_progress_bar.dart';

/// Tarjeta de Nivel + barra de XP (Inicio).
///
/// "Nivel 7 · 2,340 / 3,000 XP · faltan 660 para el nivel 8".
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    this.levelStartXp = 0,
    this.onTap,
  });

  final int level;

  /// XP total acumulado.
  final int currentXp;

  /// XP total necesario para alcanzar el siguiente nivel.
  final int nextLevelXp;

  /// XP total con el que se alcanzó el nivel actual (la barra se llena
  /// solo con el XP ganado dentro del nivel).
  final int levelStartXp;
  final VoidCallback? onTap;

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final remaining = (nextLevelXp - currentXp).clamp(0, nextLevelXp).toInt();
    final span = nextLevelXp - levelStartXp;
    final double progress = span <= 0 ? 0.0 : (currentXp - levelStartXp) / span;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  '$level',
                  style: tt.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: p.onAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nivel $level', style: tt.titleMedium?.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(currentXp)} / ${_fmt(nextLevelXp)} XP · faltan ${_fmt(remaining)} para el nivel ${level + 1}',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          XpProgressBar(value: progress),
        ],
      ),
    );
  }
}
