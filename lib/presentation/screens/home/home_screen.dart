import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/gamification.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/track.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/tracks_provider.dart';
import '../../widgets/track_actions.dart';
import '../../widgets/ui/ui.dart';
import '../scan/scan_sheet.dart';

/// Inicio (diseño "1 · Inicio").
///
/// Saludo + racha, tarjeta de nivel, "Continuar escuchando" y "Próximo logro".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(watchUserStatsProvider).value;
    final level = stats?.level ?? 1;
    final xp = stats?.totalXP ?? 0;
    final streak = stats == null ? 0 : Gamification.activeStreak(stats.currentStreakDays, stats.lastListeningDate);
    final libraryEmpty = ref.watch(watchAllTracksProvider).value?.isEmpty ?? false;
    final next = ref.watch(nextAchievementProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Row(
              children: [
                Expanded(child: ScreenTitle('Tu música hoy', subtitle: Fmt.greeting())),
                StreakBadge(days: streak, onTap: () => context.go(AppRoutes.progress)),
              ],
            ),
            const SizedBox(height: 20),
            LevelCard(
              level: level,
              currentXp: xp,
              levelStartXp: Gamification.xpToReach(level),
              nextLevelXp: Gamification.xpToReach(level + 1),
              onTap: () => context.go(AppRoutes.progress),
            ),
            const SizedBox(height: 24),
            if (libraryEmpty)
              _ScanPrompt(onScan: () => showScanSheet(context))
            else
              const _ContinueListening(),
            if (next != null) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Próximo logro'),
              const SizedBox(height: 10),
              _NextAchievementCard(
                achievement: next,
                onTap: () => context.go(AppRoutes.progressTab(1)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carrusel "Continuar escuchando". Si aún no hay historial, muestra las
/// canciones agregadas más recientemente.
class _ContinueListening extends ConsumerWidget {
  const _ContinueListening();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyPlayedProvider).value ?? const <Track>[];
    final List<Track> items;
    final String title;

    if (recent.isNotEmpty) {
      items = recent;
      title = 'Continuar escuchando';
    } else {
      final all = ref.watch(watchAllTracksProvider).value ?? const <Track>[];
      items = (List<Track>.of(all)..sort((a, b) => b.addedAt.compareTo(a.addedAt))).take(10).toList();
      title = 'Agregadas recientemente';
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          actionLabel: 'Ver todo',
          onAction: () => context.go(AppRoutes.library),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = items[i];
              return SizedBox(
                width: 120,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => ref.read(musicPlayerProvider.notifier).playTracks(items, initialIndex: i),
                  onLongPress: () => showTrackActions(context, ref, t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackCover.track(t, size: 120, showIcon: true),
                      const SizedBox(height: 6),
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(t.artist,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall?.copyWith(color: p.text2)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NextAchievementCard extends StatelessWidget {
  const _NextAchievementCard({required this.achievement, required this.onTap});

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final a = achievement;
    return AppCard(
      tone: AppCardTone.surface,
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppPalette.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: tt.titleMedium),
                Text(
                  '${Fmt.thousands(a.currentProgress)} / ${Fmt.thousands(a.targetProgress)} · +${a.xpReward} XP',
                  style: tt.bodySmall,
                ),
                const SizedBox(height: 8),
                XpProgressBar(value: a.progressPercentage, height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  const _ScanPrompt({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    return AppCard(
      tone: AppCardTone.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.library_music_rounded, color: p.accent, size: 32),
          const SizedBox(height: 12),
          Text('Empieza agregando tu música', style: tt.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Escanea tu dispositivo: cada canción que escuches suma XP y avanza tu racha.',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            label: const Text('Escanear música'),
          ),
        ],
      ),
    );
  }
}
