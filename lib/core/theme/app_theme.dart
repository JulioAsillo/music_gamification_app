import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Configuración de temas de la aplicación.
///
/// El tema se construye a partir de dos variables que elige el usuario:
/// el brillo (claro/oscuro, o sistema vía [ThemeMode]) y el [AppAccent].
class AppTheme {
  AppTheme._();

  static ThemeData light(AppAccent accent) => _build(Brightness.light, accent);
  static ThemeData dark(AppAccent accent) => _build(Brightness.dark, accent);

  static ThemeData _build(Brightness brightness, AppAccent accent) {
    final p = AppPalette.of(brightness, accent);
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: AppPalette.error,
      onError: Colors.white,
      surface: p.bg,
      onSurface: p.text,
      onSurfaceVariant: p.text2,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest: p.card,
      outline: p.divider,
      outlineVariant: p.divider,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
    );

    // Tipografía del diseño: Figtree. Los títulos de pantalla usan 26/800.
    final textTheme = GoogleFonts.figtreeTextTheme(base.textTheme)
        .apply(bodyColor: p.text, displayColor: p.text)
        .copyWith(
          headlineMedium: GoogleFonts.figtree(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.text),
          titleLarge: GoogleFonts.figtree(fontSize: 18, fontWeight: FontWeight.w700, color: p.text),
          titleMedium: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700, color: p.text),
          bodyLarge: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w500, color: p.text),
          bodyMedium: GoogleFonts.figtree(fontSize: 14, color: p.text),
          bodySmall: GoogleFonts.figtree(fontSize: 13, color: p.text2),
          labelLarge: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w700),
          labelSmall: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w500, color: p.text2),
        );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: p.divider,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.text,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.text),
      listTileTheme: ListTileThemeData(
        iconColor: p.text2,
        textColor: p.text,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          minimumSize: const Size(0, 48),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          minimumSize: const Size(0, 48),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent, textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.divider,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.divider,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.divider,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onAccent : p.text2),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.divider),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.text2),
        prefixIconColor: p.text2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accent,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? p.onAccent : p.text2,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? p.text : p.text2,
            )),
      ),
    );
  }
}
