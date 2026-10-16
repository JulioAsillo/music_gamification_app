import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_gamification_app/presentation/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'domain/services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎵 Inicializar AudioService al inicio
  await AudioPlayerService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Music Gamification',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainScreen(), // ✅ Cambiado a MainScreen
    );
  }
}
