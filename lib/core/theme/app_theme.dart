import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF8B1A1A);
  static const primaryDark = Color(0xFF6B1212);
  static const primaryLight = Color(0xFFAD2020);

  // Gold / Tibetan accent
  static const gold = Color(0xFFC49A28);
  static const goldLight = Color(0xFFE8C84A);
  static const goldDark = Color(0xFF9A7820);

  // Background
  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F1E8);

  // Card category colors
  static const cardAuspicious = Color(0xFFFDF6E3);
  static const cardNaga = Color(0xFFEBF5EB);
  static const cardInauspicious = Color(0xFFFDEAEA);
  static const cardNeutral = Color(0xFFF5F5F5);

  // Status colors
  static const statusAuspicious = Color(0xFF2E7D32);
  static const statusInauspicious = Color(0xFFC62828);
  static const statusCaution = Color(0xFFF57C00);
  static const statusNeutral = Color(0xFF757575);

  // Border / separator
  static const border = Color(0xFFE8E0D0);
  static const divider = Color(0xFFF0EAE0);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5A5A5A);
  static const textMuted = Color(0xFF9E9E9E);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textGold = Color(0xFFC49A28);

  // Calendar
  static const calendarToday = Color(0xFF8B1A1A);
  static const calendarSelected = Color(0xFFFDF6E3);
  static const calendarWeekend = Color(0xFFC62828);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      );

  static TextStyle get tibetan => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.8,
      );

  static TextStyle get tibetanLarge => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
        height: 1.8,
      );

  static TextStyle get calendarGoldNumber => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.gold,
      );

  static TextStyle get calendarDayNumber => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get quote => GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
        height: 1.7,
      );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 100;

  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get button => BorderRadius.circular(lg);
  static BorderRadius get badge => BorderRadius.circular(full);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
