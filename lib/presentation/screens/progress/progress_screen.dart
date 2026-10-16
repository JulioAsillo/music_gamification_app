import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/gamification.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/achievement.dart';
import '../../../domain/enums/achievement_status.dart';
import '../../../domain/enums/achievement_type.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/ui/ui.dart';

/// Progreso (diseños "3 · Estadísticas" y "4 · Logros").
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.initialTab = 0});

  /// 0 = Estadísticas, 1 = Logros.
  final int initialTab;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Llegar desde "Próximo logro" con ?tab=logros
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: ScreenTitle('Progreso'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedTabs(
                labels: const ['Estadísticas', 'Logros'],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _tab == 0 ? const _StatsTab(key: ValueKey('stats')) : const _AchievementsTab(key: ValueKey('ach')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Estadísticas ─────────────────────────

class _StatsTab extends ConsumerWidget {
  const _StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final stats = ref.watch(watchUserStatsProvider).value;
    final week = ref.watch(weeklyListeningProvider).value ?? List<int>.filled(7, 0);
    final genres = ref.watch(topGenresMinutesProvider).value ?? const <(String, int)>[];

    final level = stats?.level ?? 1;
    final xp = stats?.totalXP ?? 0;
    final streak = stats == null ? 0 : Gamification.activeStreak(stats.currentStreakDays, stats.lastListeningDate);
    final weekTotal = week.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _StatCard(
          icon: Icons.star_rounded,
          color: AppPalette.gold,
          label: 'Nivel',
          value: '$level · ${Fmt.thousands(xp)} XP',
          footer: XpProgressBar(
            value: _levelProgress(level, xp),
            height: 6,
            color: AppPalette.gold,
          ),
          caption: 'Faltan ${Fmt.thousands(Gamification.xpToReach(level + 1) - xp)} XP para el nivel ${level + 1}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                color: AppPalette.flame,
                label: 'Racha',
                value: '$streak ${streak == 1 ? 'día' : 'días'}',
                caption: streak > 0 ? '¡Sigue así!' : 'Escucha hoy para empezar',
                captionColor: streak > 0 ? p.accent : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_rounded,
                color: p.accent,
                label: 'Tiempo total',
                value: Fmt.hours(stats?.totalListeningMs ?? 0),
                caption: Fmt.songs(stats?.totalTracksPlayed ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Esta semana', style: tt.titleMedium)),
                  Text('${Fmt.totalDuration(weekTotal * 60000)} escuchados', style: tt.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              _WeekBars(minutes: week),
            ],
          ),
        ),
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top géneros', style: tt.titleMedium),
                const SizedBox(height: 12),
                for (final (genre, minutes) in genres) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyMedium),
                      ),
                      Text(Fmt.totalDuration(minutes * 60000), style: tt.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  XpProgressBar(value: genres.first.$2 == 0 ? 0.0 : minutes / genres.first.$2, height: 6),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static double _levelProgress(int level, int xp) {
    final start = Gamification.xpToReach(level);
    final end = Gamification.xpToReach(level + 1);
    return end <= start ? 0.0 : (xp - start) / (end - start);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.caption,
    this.captionColor,
    this.footer,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? caption;
  final Color? captionColor;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Text(label, style: tt.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: tt.headlineMedium?.copyWith(fontSize: 22)),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: tt.bodySmall?.copyWith(
                color: captionColor,
                fontWeight: captionColor != null ? FontWeight.w600 : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barras de minutos por día (lunes → domingo); hoy en color de acento.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.minutes});

  final List<int> minutes;

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now().weekday - 1;
    final max = minutes.fold<int>(0, (a, b) => b > a ? b : a);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Tooltip(
                message: '${minutes[i]} min',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: max == 0 ? 0.04 : (minutes[i] / max).clamp(0.04, 1.0)),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, f, _) => FractionallySizedBox(
                              heightFactor: f,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: i == today ? p.accent : p.divider,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _labels[i],
                      style: tt.labelSmall?.copyWith(
                        color: i == today ? p.text : p.text2,
                        fontWeight: i == today ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Logros ─────────────────────────

class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final achievements = ref.watch(sortedAchievementsProvider);

    return achievements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Text('Preparando tus logros…', style: tt.bodyMedium));
        }
        final unlocked = list.where((a) => a.status == AchievementStatus.unlocked).length;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text('$unlocked de ${list.length} desbloqueados', style: tt.bodySmall);
            }
            return _AchievementCard(achievement: list[i - 1]);
          },
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  static IconData _icon(AchievementType t) => switch (t) {
        AchievementType.streak => Icons.local_fire_department_rounded,
        AchievementType.totalTime => Icons.schedule_rounded,
        AchievementType.albumComplete => Icons.album_rounded,
        AchievementType.exploration => Icons.explore_rounded,
        AchievementType.songCount => Icons.music_note_rounded,
        AchievementType.nightOwl => Icons.dark_mode_rounded,
        AchievementType.artistDiversity => Icons.groups_rounded,
        AchievementType.special => Icons.emoji_events_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final a = achievement;
    final done = a.status == AchievementStatus.unlocked;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      borderColor: done ? AppPalette.gold.withValues(alpha: 0.5) : Colors.transparent,
      borderWidth: 2,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done ? AppPalette.gold.withValues(alpha: 0.18) : p.divider,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(a.type), color: done ? AppPalette.gold : p.text2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: tt.titleMedium),
                const SizedBox(height: 2),
                Text(a.description, style: tt.bodySmall),
                const SizedBox(height: 8),
                if (done)
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: AppPalette.success),
                      const SizedBox(width: 4),
                      Text(
                        'Desbloqueado',
                        style: tt.labelSmall?.copyWith(color: AppPalette.success, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                else ...[
                  XpProgressBar(value: a.progressPercentage, height: 6),
                  const SizedBox(height: 4),
                  Text(
                    '${Fmt.thousands(a.currentProgress)} / ${Fmt.thousands(a.targetProgress)}',
                    style: tt.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('+${a.xpReward}', style: tt.labelLarge?.copyWith(color: AppPalette.success)),
              Text('XP', style: tt.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
