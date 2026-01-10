import 'package:flutter/material.dart';
import 'package:masterpro_ai_scan_id/core/theme/app_colors.dart';
import 'package:masterpro_ai_scan_id/core/theme/app_fonts.dart';

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
        ), // End ColorScheme
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: AppColors.white,
          headerForegroundColor: AppColors.text,
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          // Colors for the days
          dayForegroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.text; // Text remains black
            }
            return AppColors.text;
          }),
          dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              // Glassy effect: Low opacity black (or primary)
              return Colors.black.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          todayForegroundColor: MaterialStateProperty.all(AppColors.red),
          todayBackgroundColor: MaterialStateProperty.all(Colors.transparent),
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
