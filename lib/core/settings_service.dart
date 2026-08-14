import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings persist di shared_preferences: voice on/off, theme mode.
///
/// Voice cue selalu Inggris (notifikasi app English-only final — lihat PRD
/// Open Questions, diputuskan user: tidak ada pilihan bahasa di v1). Tidak ada
/// field bahasa supaya YAGNI; bila nanti butuh multi-bahasa, tambahkan kembali.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kVoiceEnabled = 'voice_enabled';
  static const _kDarkTheme = 'dark_theme';
  static const _kThemeMode = 'theme_mode';

  /// One of 'system', 'light', 'dark'.
  static const defaultThemeMode = ThemeMode.system;

  bool get voiceEnabled => _prefs.getBool(_kVoiceEnabled) ?? true;
  Future<void> setVoiceEnabled(bool v) => _prefs.setBool(_kVoiceEnabled, v);

  /// Legacy bool setting (pre-3-state). Migrates to [themeMode]; kept for
  /// backward reads. New writes always go through [setThemeMode] and remove
  /// the legacy key so it can't override the new value.
  bool get darkTheme => _prefs.getBool(_kDarkTheme) ?? true;

  ThemeMode get themeMode {
    if (_prefs.containsKey(_kThemeMode)) {
      return _themeModeFromString(_prefs.getString(_kThemeMode));
    }
    // Legacy v1.1.x boolean: dark on by default.
    return _prefs.getBool(_kDarkTheme) ?? true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kThemeMode, _themeModeToString(mode));
    await _prefs.remove(_kDarkTheme);
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
