import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<String> _fontFallback = [
    'Outfit',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.outfitTextTheme(base).apply(
      fontFamilyFallback: _fontFallback,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: GoogleFonts.outfit().fontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF334155),
          fontSize: 14,
          height: 1.5,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        textStyle: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF6A2777);
          }
          return Colors.white;
        }),
        side: const BorderSide(color: Color(0xFF6A2777), width: 1.8),
      ),
      datePickerTheme: _buildDatePickerTheme(isDark: true),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
    );
  }

  static DatePickerThemeData _buildDatePickerTheme({required bool isDark}) {
    final surface = isDark ? const Color(0xFF1F142B) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF1E293B);
    final rangeBg = isDark ? const Color(0xFF4A1970) : const Color(0xFFF3E8FF);
    final mutedText = isDark ? const Color(0xFFA19BA8) : const Color(0xFF64748B);

    return DatePickerThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headerHelpStyle: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      rangePickerBackgroundColor: surface,
      rangePickerSurfaceTintColor: Colors.transparent,
      rangePickerHeaderBackgroundColor: AppColors.primary,
      rangePickerHeaderForegroundColor: Colors.white,
      rangePickerHeaderHeadlineStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      rangePickerHeaderHelpStyle: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      rangeSelectionBackgroundColor: rangeBg,
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.12),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return mutedText.withValues(alpha: 0.4);
        }
        return onSurface;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.primary;
      }),
      todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
      weekdayStyle: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: mutedText,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: GoogleFonts.outfit().fontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        textStyle: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF6A2777);
          }
          return Colors.white;
        }),
        side: const BorderSide(color: Color(0xFF6A2777), width: 1.8),
      ),
      datePickerTheme: _buildDatePickerTheme(isDark: false),
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
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
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}
