import 'package:flutter/material.dart';
import 'package:masterpro_ghidon/core/theme/app_colors.dart';
import 'package:masterpro_ghidon/core/theme/app_fonts.dart';

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.text, //
          onPrimary: AppColors.text,
          secondary: AppColors.white,
          onSecondary: AppColors.text,
          error: AppColors.red,
          onError: AppColors.white,
          onSurfaceVariant: AppColors.text,
          surface: AppColors.white,
          onSurface: AppColors.text,
        ),
        textTheme: const TextTheme(
          bodySmall: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          headlineSmall: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ));
  }
}
