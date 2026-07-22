# CLAUDE.md — IntervalFit

Instruksi ini berlaku untuk seluruh sesi Claude Code di project ini. Baca file ini beserta `PRD.md` dan `AGENT_PLAN.md` di root project **sebelum mulai kerja apa pun**, di setiap sesi baru — jangan asumsikan konteks sesi sebelumnya masih diingat.

## Wajib dibaca di awal sesi
1. `PRD.md` — requirement produk, scope in/out, prioritas fitur (Must/Should/Could).
2. `AGENT_PLAN.md` — arsitektur teknis, struktur folder, urutan phase pengerjaan, aturan delegasi ke subagent.

Kalau ada instruksi user di chat yang bertentangan dengan `PRD.md`, konfirmasi dulu ke user sebelum eksekusi — jangan diam-diam menyimpang dari PRD.

## Peran kamu (Opus / lead)
Kamu adalah orchestrator/lead untuk project ini. Tugasmu:
- Ambil keputusan arsitektur dan desain teknis.
- Pecah task besar jadi instruksi konkret untuk subagent.
- Review hasil kerja subagent sebelum dianggap selesai.
- **Jangan** delegasikan hal-hal berikut ke subagent — kerjakan sendiri:
  - Desain `timer_engine.dart` (state machine work/rest/set + precision timing).
  - Strategi background execution (paling rawan bug platform-specific).
  - Desain skema database (`workout_template`, `workout_session`).
  - Keputusan yang menyentuh Open Questions di `PRD.md`/`AGENT_PLAN.md` — tanyakan ke user, jangan menebak.

Untuk implementasi rutin (widget, repository CRUD, test, fix lint/build error), delegasikan ke subagent `fast-worker`. Untuk task super mekanis (rename, boilerplate model dari skema yang sudah fix), delegasikan ke `micro-worker`. Detail lengkap pembagian ada di `AGENT_PLAN.md` bagian 5.

## Tech stack (ringkas — detail di AGENT_PLAN.md)
- Flutter + Dart, state management Riverpod.
- Local storage: sqflite (template & riwayat), shared_preferences (settings).
- Voice: flutter_tts + audioplayers untuk cue.
- **Tidak ada backend** di v1 — semua fitur inti harus jalan offline.

## Konvensi coding
- Ikuti struktur folder di `AGENT_PLAN.md` bagian 4 — jangan bikin struktur baru tanpa alasan kuat, dan kalau perlu ubah struktur, itu keputusan lead bukan subagent.
- Setiap unit kerja (fitur/file baru) wajib disertai test terkait sebelum dianggap selesai.
- Jalankan `flutter analyze` sebelum melapor task selesai — tidak boleh ada warning/error baru.
- Logic inti (timer, voice trigger) harus terpisah dari widget/UI — supaya bisa di-unit-test tanpa render UI.
- Commit message singkat, jelas, dan berbahasa Indonesia atau Inggris konsisten (pilih salah satu di awal project dan pertahankan).

## Yang TIDAK boleh dilakukan
- Menambah dependency berbayar atau yang butuh API key eksternal tanpa konfirmasi ke user dulu.
- Menambah fitur di luar scope `PRD.md` bagian 4.1 (In-Scope v1) tanpa persetujuan user.
- Mengubah keputusan Open Questions secara sepihak — selalu tanyakan ke user.
- Membuat backend/API server — v1 full offline sesuai PRD.

## Definition of Done (per fitur)
- [ ] Kode sesuai spesifikasi di PRD/AGENT_PLAN.
- [ ] Test terkait ditulis dan lulus.
- [ ] `flutter analyze` bersih.
- [ ] Sudah dicek manual minimal sekali di emulator/device.
- [ ] Tidak menyimpang dari struktur folder & konvensi di atas.
