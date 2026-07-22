import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Menjaga proses tetap hidup saat layar terkunci / app di-background (FR-4).
///
/// Pendekatan B (lihat catatan Phase 5): kita TIDAK memindah timer/voice ke
/// isolate background. Cukup nyalakan foreground service dengan notifikasi
/// persisten → importance proses naik → Timer.periodic di UI isolate + TTS
/// tetap jalan saat terkunci. Engine (Stopwatch monotonic) sudah presisi.
///
/// ponytail: bg isolate sengaja kosong — dia cuma "pemegang" FGS. Upgrade ke
/// full-bg-isolate (jalankan engine di sini) HANYA kalau OEM agresif
/// (Xiaomi/Oppo) terbukti bunuh proses walau FGS aktif — itu ceiling yang
/// sudah ditandai di PRD sec 9.
class BackgroundKeepAlive {
  BackgroundKeepAlive._();

  static const _notifId = 888;
  static const _channelId = 'intervalfit_workout';
  static final _service = FlutterBackgroundService();

  /// Channel ke MainActivity untuk cek/minta izin notifikasi (Android 13+).
  /// FGS butuh POST_NOTIFICATIONS di-grant; kalau tidak, startForeground()
  /// crash native (tak bisa ditangkap try/catch Dart). Jadi kita gate di sini.
  static const _perm = MethodChannel('intervalfit/notifications');

  /// Minta izin POST_NOTIFICATIONS (Android 13+). Panggil sekali di main().
  /// Aman kalau channel belum ada (unit test / iOS) — return false.
  static Future<bool> requestNotificationPermission() async {
    try {
      await _perm.invokeMethod<void>('request');
      // Native menampilkan dialog izin secara async; hasil sebenarnya dicek
      // ulang lewat _hasNotificationPermission() saat start().
      return await _hasNotificationPermission();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _hasNotificationPermission() async {
    try {
      return await _perm.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Panggil sekali di main() sebelum runApp.
  static Future<void> init() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false, // hanya nyala saat sesi mulai
        autoStartOnBoot: false, // jangan respawn saat device boot (FR: sesi manual)
        // Android 14+ (targetSdk 36): startForeground WAJIB diberi type yang
        // cocok dengan manifest (specialUse) — kalau tidak, plugin fallback ke
        // TYPE_MANIFEST dan bisa lempar IllegalArgument/MissingType -> native
        // crash tak-tertangkap, lalu WatchdogReceiver respawn tiap 5s (crash loop
        // yang bertahan walau app dibuka ulang).
        foregroundServiceTypes: const [AndroidForegroundType.specialUse],
        notificationChannelId: _channelId,
        initialNotificationTitle: 'IntervalFit',
        initialNotificationContent: 'Workout session in progress',
        foregroundServiceNotificationId: _notifId,
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  /// Nyalakan FGS saat sesi latihan mulai.
  /// try/catch: aman dipanggil tanpa platform (unit test) & saat plugin belum siap.
  static Future<void> start() async {
    try {
      // Gate: tanpa izin notifikasi, startForeground() crash native (tak bisa
      // ditangkap try/catch). Skip FGS — workout tetap jalan (degradasi wajar).
      if (!await _hasNotificationPermission()) return;
      if (await _service.isRunning()) return;
      await _service.startService();
    } catch (_) {/* no platform / belum init — abaikan */}
  }

  /// Matikan FGS saat sesi selesai/stop.
  static Future<void> stop() async {
    try {
      if (await _service.isRunning()) _service.invoke('stop');
    } catch (_) {/* no platform / belum init — abaikan */}
  }
}

/// Entry-point isolate background. Sengaja minimal: hanya dengarkan sinyal stop.
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) {
  service.on('stop').listen((_) => service.stopSelf());
}
