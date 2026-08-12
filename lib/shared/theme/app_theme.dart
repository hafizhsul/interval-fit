import 'package:flutter/material.dart';

import '../design/tokens.dart';

class AppColors {
  AppColors._();

  static bool _light = false;

  static void setLight(bool value) => _light = value;

  static const _darkBackground = Color(0xFF0B0D0F);
  static const _darkSurface = Color(0xFF111518);
  static const _darkSurfaceHigh = Color(0xFF181E22);
  static const _darkBorder = Color(0xFF293238);
  static const _darkOnSurface = Color(0xFFF4F1EA);
  static const _darkOnSurfaceMute = Color(0xFF9AA6A8);
  static const _darkOnSurfaceDim = Color(0xFF566166);

  static const _lightBackground = Color(0xFFF7F4EF);
  static const _lightSurface = Color(0xFFFFFCF7);
  static const _lightSurfaceHigh = Color(0xFFFFFFFF);
  static const _lightBorder = Color(0xFFE3DCD3);
  static const _lightOnSurface = Color(0xFF1D282A);
  static const _lightOnSurfaceMute = Color(0xFF667477);
  static const _lightOnSurfaceDim = Color(0xFFA3ADAE);

  static Color get background => _light ? _lightBackground : _darkBackground;
  static Color get surface => _light ? _lightSurface : _darkSurface;
  static Color get surfaceHigh => _light ? _lightSurfaceHigh : _darkSurfaceHigh;
  static Color get border => _light ? _lightBorder : _darkBorder;
  static Color get onSurface => _light ? _lightOnSurface : _darkOnSurface;
  static Color get onSurfaceMute =>
      _light ? _lightOnSurfaceMute : _darkOnSurfaceMute;
  static Color get onSurfaceDim =>
      _light ? _lightOnSurfaceDim : _darkOnSurfaceDim;

  static const Color primary = Color(0xFFFF7847);
  static const Color work = Color(0xFFFF6B35);
  static const Color rest = Color(0xFF0A84FF);
  static const Color warmup = Color(0xFFFFC857);
  static const Color cooldown = Color(0xFF61C8D8);
  static const Color done = Color(0xFFFF6B35);
  static const Color destructive = Color(0xFFFF453A);

  static Color get muted => onSurfaceMute;
  static const Color accent = primary;
}

class AppTheme {
  AppTheme._();

  static const _sans = 'Barlow';
  static const _condensed = 'BarlowCondensed';

  static ThemeData get dark => _buildTheme(false);
  static ThemeData get light => _buildTheme(true);

  static ThemeData _buildTheme(bool isLight) {
    AppColors.setLight(isLight);
    final background = isLight
        ? const Color(0xFFF7F4EF)
        : const Color(0xFF0B0D0F);
    final surface = isLight ? const Color(0xFFFFFCF7) : const Color(0xFF111518);
    final surfaceHigh = isLight ? Colors.white : const Color(0xFF181E22);
    final border = isLight ? const Color(0xFFE3DCD3) : const Color(0xFF293238);
    final foreground = isLight
        ? const Color(0xFF1D282A)
        : const Color(0xFFF4F1EA);
    final muted = isLight ? const Color(0xFF667477) : const Color(0xFF9AA6A8);
    final dim = isLight ? const Color(0xFFA3ADAE) : const Color(0xFF566166);
    final base = isLight
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: isLight ? Colors.white : background,
      primaryContainer: isLight ? const Color(0xFFFFE2D4) : surfaceHigh,
      secondary: AppColors.rest,
      surface: surface,
      surfaceBright: surfaceHigh,
      surfaceContainer: surfaceHigh,
      surfaceContainerHighest: isLight ? const Color(0xFFF0EBE4) : surfaceHigh,
      onSecondary: Colors.white,
      onSurface: foreground,
      outline: border,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: _sans,
          bodyColor: foreground,
          displayColor: foreground,
        )
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: _condensed,
            fontSize: 140,
            fontWeight: FontWeight.w700,
            height: 1,
            color: foreground,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          displayMedium: TextStyle(
            fontFamily: _condensed,
            fontSize: 64,
            fontWeight: FontWeight.w700,
            height: 1,
            color: foreground,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          headlineLarge: TextStyle(
            fontFamily: _condensed,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: foreground,
          ),
          headlineMedium: TextStyle(
            fontFamily: _condensed,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: muted,
          ),
          titleLarge: TextStyle(
            fontFamily: _sans,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
          bodyLarge: TextStyle(
            fontFamily: _sans,
            fontSize: 16,
            color: foreground,
          ),
          bodyMedium: TextStyle(fontFamily: _sans, fontSize: 14, color: muted),
          labelLarge: TextStyle(
            fontFamily: _sans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: foreground,
          ),
          labelSmall: TextStyle(
            fontFamily: _sans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: muted,
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: border, space: 1),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: background,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _condensed,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        iconTheme: IconThemeData(color: foreground),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : dim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.3)
              : surfaceHigh;
        }),
      ),
    );
  }
}
