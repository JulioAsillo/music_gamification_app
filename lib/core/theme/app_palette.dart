import 'package:flutter/material.dart';

/// Colores de acento seleccionables por el usuario (pantalla Perfil → Apariencia).
///
/// Cada acento tiene una variante para tema oscuro y otra para tema claro,
/// elegidas para mantener buen contraste sobre el fondo de cada tema.
enum AppAccent {
  indigo('Índigo', Color(0xFF6366F1), Color(0xFF4F46E5), Colors.white),
  esmeralda('Esmeralda', Color(0xFF10B981), Color(0xFF047857), Colors.white),
  ambar('Ámbar', Color(0xFFFBBF24), Color(0xFFB45309), Color(0xFF18181B)),
  rosa('Rosa', Color(0xFFEC4899), Color(0xFFBE185D), Colors.white),
  cian('Cian', Color(0xFF22D3EE), Color(0xFF0E7490), Color(0xFF18181B)),
  coral('Coral', Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFF18181B));

  const AppAccent(this.label, this.dark, this.light, this.onDark);

  /// Nombre visible en la UI.
  final String label;

  /// Color del acento en tema oscuro.
  final Color dark;

  /// Color del acento en tema claro.
  final Color light;

  /// Color del texto/icono sobre el acento en tema oscuro.
  /// En tema claro siempre es blanco.
  final Color onDark;

  Color colorFor(Brightness b) => b == Brightness.dark ? dark : light;
  Color onColorFor(Brightness b) => b == Brightness.dark ? onDark : Colors.white;

  static AppAccent fromName(String? name) =>
      AppAccent.values.firstWhere((a) => a.name == name, orElse: () => AppAccent.indigo);
}

/// Tokens de color del sistema de diseño, accesibles con `context.palette`.
///
/// Se registra como [ThemeExtension] en [AppTheme], así cada widget lee
/// los colores del tema activo sin depender de constantes fijas.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.text2,
    required this.divider,
    required this.accent,
    required this.onAccent,
  });

  /// Fondo de las pantallas.
  final Color bg;

  /// Superficie secundaria: buscador, botones redondos, tabs segmentados, nav.
  final Color surface;

  /// Fondo de tarjetas destacadas (Nivel, estadísticas, logros).
  final Color card;

  /// Texto principal.
  final Color text;

  /// Texto secundario (subtítulos, duraciones, etiquetas).
  final Color text2;

  /// Bordes, separadores y fondo de barras de progreso.
  final Color divider;

  /// Color de acento activo (elegido por el usuario).
  final Color accent;

  /// Texto/icono sobre el acento.
  final Color onAccent;

  // Colores semánticos fijos (no dependen del tema)
  static const Color gold = Color(0xFFFBBF24);
  static const Color flame = Color(0xFFFB923C);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  /// Gradientes para portadas de canciones sin carátula.
  static const List<List<Color>> coverGradients = [
    [Color(0xFF6366F1), Color(0xFFEC4899)],
    [Color(0xFFF97316), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF0EA5E9)],
    [Color(0xFF8B5CF6), Color(0xFF0F172A)],
    [Color(0xFFF43F5E), Color(0xFFFBBF24)],
    [Color(0xFF334155), Color(0xFF64748B)],
  ];

  static const _darkBase = (
    bg: Color(0xFF0F0F1E),
    surface: Color(0xFF1A1B2E),
    card: Color(0xFF1F2937),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFA1A1AA),
    divider: Color(0xFF2D2E47),
  );

  static const _lightBase = (
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    card: Color(0xFFF3F4F6),
    text: Color(0xFF18181B),
    text2: Color(0xFF63636B),
    divider: Color(0xFFE4E6EA),
  );

  factory AppPalette.of(Brightness brightness, AppAccent accent) {
    final b = brightness == Brightness.dark ? _darkBase : _lightBase;
    return AppPalette(
      bg: b.bg,
      surface: b.surface,
      card: b.card,
      text: b.text,
      text2: b.text2,
      divider: b.divider,
      accent: accent.colorFor(brightness),
      onAccent: accent.onColorFor(brightness),
    );
  }

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? text,
    Color? text2,
    Color? divider,
    Color? accent,
    Color? onAccent,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Acceso corto: `context.palette.accent`, `context.palette.text2`, etc.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      AppPalette.of(Theme.of(this).brightness, AppAccent.indigo);
}
