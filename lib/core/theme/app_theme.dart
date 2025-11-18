import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Configuración de temas de la aplicación
class AppTheme {
  AppTheme._();

  // 🌙 TEMA OSCURO
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTextStyles.fontFamily,

    // COLORES PRINCIPALES
    colorScheme: ColorScheme.dark(
      primary: AppColors.accentDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.primaryDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,

    // APP BAR
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
      ),
    ),

    // CARDS
    cardTheme: CardThemeData(
      color: AppColors.cardElevationDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // BOTONES ELEVADOS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentDark,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // BOTTOM NAVIGATION - ✅ CORREGIDO: bottomNavigationBarTheme (sin Data)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryDark,
      selectedItemColor: AppColors.accentDark,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // ☀️ TEMA CLARO
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTextStyles.fontFamily,

    // COLORES PRINCIPALES
    colorScheme: ColorScheme.light(
      primary: AppColors.accentLight,
      secondary: AppColors.secondaryLight,
      surface: AppColors.primaryLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: AppColors.textPrimaryLight,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: AppColors.backgroundLight,

    // APP BAR
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
      ),
    ),

    // CARDS
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // BOTONES ELEVADOS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentLight,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentLight,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // BOTTOM NAVIGATION - ✅ CORREGIDO: bottomNavigationBarTheme (sin Data al final)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.accentLight,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
