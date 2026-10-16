import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/player/player_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/progress/progress_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';

/// Rutas de la app.
///
/// ```
/// StatefulShellRoute (bottom nav, cada pestaña conserva su pila y scroll)
/// ├── /inicio
/// ├── /biblioteca
/// ├── /progreso        (?tab=logros abre directo en Logros)
/// └── /perfil
/// /reproductor         (pantalla completa, sube desde abajo, tapa el nav)
/// ```
abstract final class AppRoutes {
  static const home = '/inicio';
  static const library = '/biblioteca';
  static const progress = '/progreso';
  static const profile = '/perfil';
  static const player = '/reproductor';

  static String progressTab(int tab) => tab == 1 ? '$progress?tab=logros' : progress;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.progress,
            builder: (context, state) => ProgressScreen(
              initialTab: state.uri.queryParameters['tab'] == 'logros' ? 1 : 0,
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: AppRoutes.player,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        fullscreenDialog: true,
        child: const PlayerScreen(),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: child,
          );
        },
      ),
    ),
  ],
);
