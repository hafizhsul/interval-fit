import 'package:flutter/material.dart';

/// Theme IntervalFit — athletic, high-contrast (PRD NFR aksesibilitas: angka
/// besar & kontras tinggi, terbaca sambil bergerak). Font Barlow (di-bundle,
/// bukan google_fonts — app offline-first, tak boleh fetch jaringan).
class AppColors {
  AppColors._();

  // Fase — warna fungsional (signaling), bukan dekorasi. Kontras tinggi.
  /// Fase kerja — merah energik.
  static const Color work = Color(0xFFE53935);

  /// Fase istirahat — biru tenang.
  static const Color rest = Color(0xFF1E88E5);

  /// Warm-up — amber.
  static const Color warmup = Color(0xFFFB8C00);

  /// Cooldown — teal.
  static const Color cooldown = Color(0xFF00897B);

  // Brand / surface (design-system: energy orange + success green).
  static const Color primary = Color(0xFFF97316); // energy orange
  static const Color accent = Color(0xFF22C55E); // success green (CTA start)
  static const Color background = Color(0xFF0F172A); // slate-900
  static const Color surface = Color(0xFF1E293B); // slate-800
  static const Color border = Color(0xFF334155); // slate-700
  static const Color onSurface = Color(0xFFF8FAFC); // near-white
  static const Color muted = Color(0xFF94A3B8); // slate-400 (secondary text)
  static const Color destructive = Color(0xFFEF4444); // stop/hapus
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
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: AppColors.border,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: base.textTheme
          .apply(fontFamily: _sans, bodyColor: AppColors.onSurface, displayColor: AppColors.onSurface)
          .copyWith(
            // Angka timer full-screen — condensed, sangat besar, tabular.
            displayLarge: const TextStyle(
              fontFamily: _condensed,
              fontSize: 140,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            headlineMedium: const TextStyle(
              fontFamily: _condensed,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            titleLarge: const TextStyle(fontWeight: FontWeight.w600),
            labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          minimumSize: const Size(0, 52), // >=44pt touch target
          textStyle: const TextStyle(fontFamily: _sans, fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }
}
