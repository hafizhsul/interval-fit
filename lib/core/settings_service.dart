import 'package:shared_preferences/shared_preferences.dart';

/// Settings persist di shared_preferences: voice on/off (FR-8).
///
/// Voice cue selalu Inggris (notifikasi app English-only final — lihat PRD
/// Open Questions, diputuskan user: tidak ada pilihan bahasa di v1). Tidak ada
/// field bahasa supaya YAGNI; bila nanti butuh multi-bahasa, tambahkan kembali.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kVoiceEnabled = 'voice_enabled';

  bool get voiceEnabled => _prefs.getBool(_kVoiceEnabled) ?? true;
  Future<void> setVoiceEnabled(bool v) => _prefs.setBool(_kVoiceEnabled, v);
}
