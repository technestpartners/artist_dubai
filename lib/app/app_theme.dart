import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.black,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF6A2777),
        selectionColor: Color(0xFFE9D5FF),
        selectionHandleColor: Color(0xFF6A2777),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF6A2777),
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: Colors.white,
        disabledActionTextColor: Colors.white70,
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF6A2777),
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: Colors.white,
        disabledActionTextColor: Colors.white70,
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}
