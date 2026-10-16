import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/services/gamification_service.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/ui/ui.dart';

/// Contenedor de las 4 pestañas: contenido + mini-player + barra de navegación.
///
/// El mini-player vive aquí (y no en cada pantalla) para que persista
/// al cambiar de pestaña, como en el diseño. También muestra los avisos de
/// logro desbloqueado y subida de nivel.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: 'Biblioteca',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: 'Progreso',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    ),
  ];

  void _onTap(int index) {
    // Tocar la pestaña activa vuelve a su pantalla raíz.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gamificationEventsProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      final (icon, text) = switch (event) {
        AchievementUnlocked(:final title, :final xp) => (Icons.emoji_events_rounded, 'Logro desbloqueado: $title · +$xp XP'),
        LevelUp(:final level) => (Icons.star_rounded, '¡Subiste al nivel $level!'),
        XpGained() => (null, null),
      };
      if (text == null) return; // el +XP por canción ya se ve en el reproductor
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: AppPalette.gold),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ],
            ),
            action: event is AchievementUnlocked
                ? SnackBarAction(label: 'Ver', onPressed: () => context.go(AppRoutes.progressTab(1)))
                : null,
          ),
        );
    });

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: _destinations,
          ),
        ],
      ),
    );
  }
}
