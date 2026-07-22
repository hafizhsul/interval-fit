/// Format detik -> mm:ss. Dipakai timer & riwayat.
String formatMmSs(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final m = s ~/ 60;
  final sec = s % 60;
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

/// Ringkasan durasi untuk summary template: "90s" atau "2m" bila kelipatan 60.
String shortDuration(int seconds) {
  if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60}m';
  return '${seconds}s';
}
