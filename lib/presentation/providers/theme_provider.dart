import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_palette.dart';

/// Instancia de SharedPreferences cargada en `main()` antes de `runApp`.
///
/// Se inyecta con `ProviderScope(overrides: [...])` para que los notifiers
/// lean las preferencias guardadas de forma síncrona (sin parpadeo de tema).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider debe sobreescribirse en main()'),
);

const _kThemeModeKey = 'theme_mode';
const _kAccentKey = 'accent_color';

/// Modo de tema: Claro / Oscuro / Sistema. Se persiste.
///
/// Provider escrito a mano (sin build_runner) para que el tema no dependa
/// de regenerar código.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_kThemeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark, // Por defecto modo oscuro
    );
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, mode.name);
  }

  void setLightMode() => setMode(ThemeMode.light);
  void setDarkMode() => setMode(ThemeMode.dark);
  void setSystemMode() => setMode(ThemeMode.system);

  /// Alterna entre claro y oscuro (si está en Sistema, pasa a Claro).
  void toggleTheme() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

/// Color de acento elegido por el usuario. Se persiste.
final accentColorProvider = NotifierProvider<AccentColorNotifier, AppAccent>(AccentColorNotifier.new);

class AccentColorNotifier extends Notifier<AppAccent> {
  @override
  AppAccent build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_kAccentKey);
    return AppAccent.fromName(saved);
  }

  void setAccent(AppAccent accent) {
    state = accent;
    ref.read(sharedPreferencesProvider).setString(_kAccentKey, accent.name);
  }
}
