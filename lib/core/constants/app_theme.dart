import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary      = Color(0xFFC15F3C); // Color(0xFFDA7756);// Color(0xFF1F4E79);
  static const Color secondary1    = Color(0xFF2E75B6);
  static const Color secondary    = Color(0xFFDA7756);
  static const Color accent       = Color(0xFFC55A11);
  static const Color gold         = Color(0xFFFFB800);
  static const Color background   = Color(0xFF0D0D0D);
  static const Color surface      = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF262626);
  static const Color cardBg       = Color(0xFF1E1E1E);
  static const Color textPrimary  = Color(0xFFF5F5F5);
  static const Color textSecondary= Color(0xFFAAAAAA);
  static const Color textHint     = Color(0xFF666666);
  static const Color divider      = Color(0xFF2A2A2A);
  static const Color error        = Color(0xFFCF6679);
  static const Color success      = Color(0xFF4CAF50);
  static const Color locked       = Color(0xFF3A3A3A);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      secondary: AppColors.secondary,
      surface:   AppColors.surface,
      error:     AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.comfortaaTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:  const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      headlineLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      headlineMedium:const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge:    const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium:   const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      bodyLarge:     const TextStyle(color: AppColors.textPrimary),
      bodyMedium:    const TextStyle(color: AppColors.textSecondary),
      bodySmall:     const TextStyle(color: AppColors.textHint),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: const BorderSide(color: AppColors.secondary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: AppColors.divider),
    ),
  );
}
