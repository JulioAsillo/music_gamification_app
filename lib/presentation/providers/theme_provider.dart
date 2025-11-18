import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// Notifier para cambiar el tema
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.dark; // Por defecto modo oscuro
  }

  /// Cambiar a modo claro
  void setLightMode() {
    state = ThemeMode.light;
  }

  /// Cambiar a modo oscuro
  void setDarkMode() {
    state = ThemeMode.dark;
  }

  /// Toggle entre claro y oscuro
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
