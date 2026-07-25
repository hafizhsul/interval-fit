import 'package:flutter/material.dart';

import '../design/tokens.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0B);
  static const Color surfaceHigh = Color(0xFF15151A);
  static const Color border = Color(0xFF1F1F26);
  static const Color onSurface = Color(0xFFF5F5F7);
  static const Color onSurfaceMute = Color(0xFF8E8E93);
  static const Color onSurfaceDim = Color(0xFF48484A);

  static const Color primary = Color(0xFFFF6B35);
  static const Color work = Color(0xFFFF6B35);
  static const Color rest = Color(0xFF0A84FF);
  static const Color warmup = Color(0xFFFFD60A);
  static const Color cooldown = Color(0xFF5AC8FA);
  static const Color done = Color(0xFFFF6B35);
  static const Color destructive = Color(0xFFFF453A);

  static const Color muted = onSurfaceMute;
  static const Color accent = primary;
}

class AppTheme {
  AppTheme._();

  static const _sans = 'Barlow';
  static const _condensed = 'BarlowCondensed';

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.surfaceHigh,
      secondary: AppColors.rest,
      surface: AppColors.surface,
      surfaceBright: AppColors.surface,
      surfaceContainer: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      onSurface: AppColors.onSurface,
      outline: AppColors.border,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: base.textTheme
          .apply(
            fontFamily: _sans,
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: _condensed,
              fontSize: 140,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            displayMedium: const TextStyle(
              fontFamily: _condensed,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            headlineLarge: const TextStyle(
              fontFamily: _condensed,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurface,
            ),
            headlineMedium: const TextStyle(
              fontFamily: _condensed,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceMute,
            ),
            titleLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            bodyLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurface,
            ),
            bodyMedium: const TextStyle(
              fontFamily: _sans,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceMute,
            ),
            labelLarge: const TextStyle(
              fontFamily: _sans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurface,
            ),
            labelSmall: const TextStyle(
              fontFamily: _sans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceMute,
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _condensed,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.onSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.onSurfaceDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceHigh;
        }),
      ),
    );
  }
}