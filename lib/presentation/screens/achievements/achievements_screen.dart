import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/enums/achievement_status.dart';
import '../../providers/achievements_provider.dart';

/// Pantalla de logros
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(watchAllAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logros',
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: AppColors.accentDark.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay logros todavía',
                    style: AppTextStyles.heading2(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comienza a escuchar música para desbloquear logros',
                    style: AppTextStyles.bodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementCard(
                title: achievement.title,
                description: achievement.description,
                isUnlocked: achievement.status.isUnlocked,
                progress: achievement.progressPercentage,
                xpReward: achievement.xpReward,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

/// Card de logro
class _AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isUnlocked;
  final double progress;
  final int xpReward;

  const _AchievementCard({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progress,
    required this.xpReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardElevationDark,
        borderRadius: BorderRadius.circular(12),
        border: isUnlocked
            ? Border.all(
          color: AppColors.achievementGold.withOpacity(0.5),
          width: 2,
        )
            : null,
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.achievementGold.withOpacity(0.2)
                  : AppColors.textSecondaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events,
              color: isUnlocked
                  ? AppColors.achievementGold
                  : AppColors.textSecondaryDark,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.achievementTitle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.achievementDescription(context),
                ),
                const SizedBox(height: 8),
                if (!isUnlocked) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.textSecondaryDark.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentDark,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% completado',
                    style: AppTextStyles.bodySmall(context),
                  ),
                ],
                if (isUnlocked)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Desbloqueado',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // XP
          Column(
            children: [
              Text(
                '+$xpReward',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.xpBarFill,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'XP',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
