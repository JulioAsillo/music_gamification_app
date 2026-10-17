import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_info.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/services/audio_player_service.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎵 Inicializar AudioService al inicio
  await AudioPlayerService.instance.initialize();

  // 🎨 Preferencias de tema (modo + acento) cargadas antes de pintar la app
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      routerConfig: appRouter,
    );
  }
}
