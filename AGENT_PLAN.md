# AGENT_PLAN.md — IntervalFit (Aplikasi Timer Olahraga Interval)

> File ini adalah spesifikasi persisten untuk AI coding agent (Claude Code). Baca file ini di awal setiap sesi sebelum mulai kerja, agar scope tetap konsisten lintas sesi.

---

## 1. Ringkasan Project

**Nama kerja:** IntervalFit
**Deskripsi:** Aplikasi mobile untuk latihan interval (skipping, jalan cepat, lari, atau olahraga bebas lainnya) dengan waktu **kerja (work)** dan **istirahat (rest)** yang bisa diatur per set, jumlah set custom, dan voice countdown "3, 2, 1" otomatis menjelang setiap set/rest berakhir.

**Target pengguna:** Individu yang latihan mandiri (bukan aplikasi multi-user/sosial di versi awal).

**Prinsip desain:**
- Offline-first — tidak butuh backend untuk fungsi inti (timer, voice, riwayat lokal).
- UI custom, bukan template generik — timer harus terasa "hidup" (visual progress ring, warna beda untuk work/rest).
- Free & self-hosted tooling, tidak ada dependency berbayar.

---

## 2. Tech Stack

| Layer | Pilihan | Alasan |
|---|---|---|
| Framework | **Flutter** (Dart) | Cross-platform (Android + iOS) satu codebase, sesuai preferensi project sebelumnya |
| State management | **Riverpod** | Ringan, testable, cocok untuk timer state yang butuh presisi |
| Local storage | **sqflite** (riwayat workout & template) + **shared_preferences** (settings ringan) | Gratis, self-hosted di device, tidak butuh server |
| Voice/audio | **flutter_tts** untuk countdown suara ("3", "2", "1", "mulai", "istirahat") + **audioplayers** untuk beep/sound cue | flutter_tts gratis & offline setelah TTS engine ter-cache di device |
| Timer engine | `Stopwatch` + `Ticker`/`Timer.periodic` custom, **bukan** package timer generik | Butuh presisi tinggi & kontrol penuh untuk callback voice per detik |
| Background execution | **flutter_background_service** atau platform-specific (WorkManager/BGTaskScheduler) | Timer harus tetap jalan saat layar mati/app minimized |
| Testing | `flutter_test` + `mocktail` | Bawaan Flutter, gratis |

**Tidak pakai backend di versi awal.** Kalau nanti butuh sync antar device atau leaderboard, itu masuk fase v2 (lihat Open Questions).

---

## 3. Fitur Inti (v1)

### 3.1 Interval Timer
- User bisa membuat **workout template**: nama, jenis olahraga (skipping/jalan/lari/custom), jumlah set, durasi kerja per set, durasi istirahat per set.
- Opsional: warm-up time sebelum set pertama, cooldown setelah set terakhir.
- Timer berjalan full-screen dengan:
  - Progress ring/bar visual per set.
  - Angka detik besar & jelas (harus kebaca sambil olahraga/lari).
  - Indikator set ke-berapa dari total (misal "Set 3/8").
  - Warna berbeda jelas antara fase **work** dan **rest**.

### 3.2 Voice Countdown
- 3 detik sebelum **work** berakhir → suara "3, 2, 1" lalu cue "istirahat".
- 3 detik sebelum **rest** berakhir → suara "3, 2, 1" lalu cue "mulai" / nama olahraga.
- Voice harus tetap jalan walau layar terkunci atau app di background (pakai background service).
- Ada toggle: suara ON/OFF, dan pilihan bahasa (ID/EN) untuk voice cue.
- Fallback: kalau TTS gagal load, pakai beep sound sebagai cue minimal.

### 3.3 Riwayat & Template
- Simpan riwayat sesi selesai (tanggal, jenis olahraga, total durasi, jumlah set selesai).
- Simpan template workout supaya bisa dipakai ulang tanpa input ulang.
- Template default bawaan: "Skipping Pemula" (30s kerja/30s rest x10), "Lari Interval" (1 menit kerja/1 menit rest x8) — biar app langsung kepake tanpa setup.

### 3.4 Kontrol Saat Timer Jalan
- Pause/resume.
- Skip ke set berikutnya.
- Stop & simpan progress parsial ke riwayat.

---

## 4. Struktur Folder (target)

```
lib/
  main.dart
  core/
    timer_engine.dart        # logic inti timer, terpisah dari UI
    voice_service.dart        # wrapper flutter_tts + audio cue
    background_service.dart   # keep timer alive di background
  data/
    models/
      workout_template.dart
      workout_session.dart
    repositories/
      template_repository.dart   # sqflite
      history_repository.dart    # sqflite
  features/
    home/
    template_builder/
    active_workout/
    history/
    settings/
  shared/
    widgets/
    theme/
test/
  core/timer_engine_test.dart
  data/repositories/...
```

---

## 5. Setup Orchestrator: Opus (Lead) + Sonnet/Haiku (Executor)

Tujuan: hemat token dengan memisahkan **keputusan arsitektur/desain** (butuh reasoning dalam) dari **eksekusi mekanis** (implementasi rutin).

### 5.1 Subagent yang perlu dibuat (`.claude/agents/`)

**`fast-worker.md`** (model: `sonnet`)
```yaml
---
name: fast-worker
description: Eksekusi implementasi rutin - nulis widget, model, repository, run test, fix lint error. Ikuti spesifikasi persis, jangan improvisasi arsitektur atau ubah struktur folder.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---
Kamu adalah executor untuk project IntervalFit. Kerjakan instruksi implementasi
persis sesuai yang diminta oleh lead. Jangan mengambil keputusan desain baru -
kalau spesifikasi kurang jelas, laporkan balik ke lead, jangan menebak.
Setelah selesai satu unit kerja, jalankan `flutter analyze` dan test terkait
sebelum melapor selesai.
```

**`micro-worker.md`** (model: `haiku`, opsional untuk task super simpel)
```yaml
---
name: micro-worker
description: Task sangat mekanis - rename, formatting, generate boilerplate model/entity sederhana, nulis test case dasar dari template yang sudah ada.
tools: Read, Write, Edit, Bash
model: haiku
---
Kerjakan task paling sederhana dan berulang. Jangan dipakai untuk logic timer
atau voice service - itu butuh reasoning lebih, delegasikan ke fast-worker atau
kerjakan langsung oleh lead.
```

### 5.2 Aturan Delegasi (masuk ke `CLAUDE.md` project)

**Lead (Opus / model sesi utama) kerjakan sendiri, JANGAN didelegasikan:**
- Desain arsitektur `timer_engine.dart` (logic precision timer + callback voice trigger).
- Strategi background execution (paling rawan bug platform-specific).
- Desain skema database (`workout_template`, `workout_session`).
- Review & keputusan final sebelum merge/selesai fitur besar.

**Delegasikan ke `fast-worker` (Sonnet):**
- Implementasi UI widget berdasarkan spek yang sudah lead tentukan.
- Implementasi repository CRUD (sqflite) mengikuti skema yang lead sudah desain.
- Nulis & jalankan unit test untuk logic yang sudah lead tulis.
- Integrasi `flutter_tts`/`audioplayers` mengikuti interface yang lead desain.
- Fix error dari `flutter analyze` / build error.

**Delegasikan ke `micro-worker` (Haiku), kalau dipakai:**
- Generate model class dari skema yang sudah fix.
- Formatting, rename variabel/file, boilerplate test skeleton.

**Contoh instruksi ke Opus (di awal sesi):**
> "Bangun fitur active_workout screen. Sebelum implementasi, desain dulu state
> machine untuk timer (work → rest → work → ... → done) dan interface
> VoiceService. Setelah desain fix, delegasikan implementasi widget & wiring ke
> fast-worker."

---

## 6. Urutan Pengerjaan (Phase)

1. **Phase 0 — Setup project**: init Flutter project, folder structure, dependency (pubspec.yaml), theme dasar. *(bisa fast-worker, spek dari lead)*
2. **Phase 1 — Timer engine** (core, tanpa UI): state machine work/rest/set, unit test presisi. *(lead desain, fast-worker implementasi & test)*
3. **Phase 2 — Voice service**: wrapper TTS + audio cue, trigger di detik ke-3 sebelum fase berakhir. *(lead desain interface, fast-worker implementasi)*
4. **Phase 3 — Data layer**: model + sqflite repository untuk template & history. *(lead desain skema, fast-worker/micro-worker implementasi)*
5. **Phase 4 — UI**: home, template builder, active workout screen, history screen. *(fast-worker, mayoritas)*
6. **Phase 5 — Background execution**: pastikan timer + voice tetap jalan saat app minimized/layar mati. *(lead handle, ini paling rawan platform-specific bug)*
7. **Phase 6 — Polish & testing**: end-to-end test manual di device asli (Android minimal, iOS kalau ada device), battery/performance check.

---

## 7. Open Questions (perlu diputuskan sebelum/selama build)

- [ ] Suara voice: pakai TTS on-device (gratis, kualitas bervariasi per device) atau rekam suara sendiri/generate sekali lalu bundel sebagai file audio (kualitas konsisten, tapi nambah ukuran app & kerja tambahan)?
- [ ] Support iOS di v1, atau Android dulu lalu iOS menyusul?
- [ ] Perlu wearable integration (misal notifikasi ke smartwatch) di v1, atau v2?
- [ ] Unit waktu: hanya detik, atau perlu opsi menit untuk set kerja/rest yang panjang?
- [ ] Apakah butuh akun/login sama sekali, atau full lokal tanpa akun untuk v1?

---

## 8. Testing Checklist (minimum sebelum dianggap "selesai")

- [ ] Timer akurat ±0.1s dibanding stopwatch fisik untuk sesi 10 menit.
- [ ] Voice countdown konsisten muncul tepat di detik ke-3, 2, 1 sebelum transisi fase.
- [ ] Timer & voice tetap jalan saat: layar dikunci, app di-background, notifikasi lain masuk.
- [ ] Pause/resume tidak menggeser akurasi waktu total.
- [ ] Riwayat tersimpan benar walau app di-force-close di tengah sesi (progress parsial).
- [ ] Template default bisa langsung dipakai tanpa setup manual.
