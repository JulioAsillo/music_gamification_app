import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/stats_provider.dart';

/// Pantalla de estadísticas
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(watchUserStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Estadísticas',
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: userStatsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(
              child: Text('No hay estadísticas disponibles'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de nivel y XP
                _StatCard(
                  icon: Icons.star,
                  title: 'Nivel',
                  value: stats.level.toString(),
                  subtitle: '${stats.totalXP} XP',
                  color: AppColors.achievementGold,
                ),
                const SizedBox(height: 16),

                // Card de racha
                _StatCard(
                  icon: Icons.local_fire_department,
                  title: 'Racha',
                  value: '${stats.currentStreakDays} días',
                  subtitle: '¡Sigue así!',
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),

                // Card de tiempo total
                _StatCard(
                  icon: Icons.access_time,
                  title: 'Tiempo Total',
                  value: '${stats.totalListeningHours.toStringAsFixed(1)} hrs',
                  subtitle: '${stats.totalTracksPlayed} canciones',
                  color: AppColors.accentDark,
                ),
                const SizedBox(height: 24),

                // Sección de géneros (placeholder)
                Text(
                  'Top Géneros',
                  style: AppTextStyles.heading3(context),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Próximamente: Gráfico de géneros',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
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

/// Card de estadística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardElevationDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.heading2(context),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
