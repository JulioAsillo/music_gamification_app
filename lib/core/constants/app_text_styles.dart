import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto consistentes en toda la app
class AppTextStyles {
  AppTextStyles._();

  // 📱 BASE FONT FAMILY
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // 🔤 HEADINGS
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.displayLarge?.color,
    height: 1.2,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.displayMedium?.color,
    height: 1.3,
  );

  static TextStyle heading3(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.displaySmall?.color,
    height: 1.3,
  );

  // 📝 BODY TEXT
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodyLarge?.color,
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodyMedium?.color,
    height: 1.5,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodySmall?.color,
    height: 1.4,
  );

  // 🎵 MÚSICA ESPECÍFICO
  static TextStyle trackTitle(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).textTheme.bodyLarge?.color,
  );

  static TextStyle artistName(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
  );

  static TextStyle albumName(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
  );

  // 🔢 NÚMEROS Y STATS
  static TextStyle statNumber(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.displayLarge?.color,
    height: 1,
  );

  static TextStyle statLabel(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
    letterSpacing: 0.5,
  );

  // 🏆 LOGROS
  static TextStyle achievementTitle(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).textTheme.bodyLarge?.color,
  );

  static TextStyle achievementDescription(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
    height: 1.4,
  );

  // 🔘 BOTONES
  static TextStyle button(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle buttonSmall(BuildContext context) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );
}
