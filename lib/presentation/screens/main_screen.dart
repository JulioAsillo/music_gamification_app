import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'library/library_screen.dart';
import 'stats/stats_screen.dart';
import 'achievements/achievements_screen.dart';
import 'settings/settings_screen.dart';

/// Provider para el índice del tab actual
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Pantalla principal con navegación por tabs
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    // Lista de pantallas
    final screens = [
      const LibraryScreen(),
      const StatsScreen(),
      const AchievementsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
