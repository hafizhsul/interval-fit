# PRD — IntervalFit (Aplikasi Timer Olahraga Interval)

## 1. Latar Belakang

Banyak orang latihan interval (skipping, jalan cepat, lari) secara mandiri tanpa pelatih, dan biasanya mengandalkan stopwatch manual atau aplikasi timer generik yang tidak dirancang khusus untuk olahraga — tidak ada cue suara, susah dibaca sambil bergerak, atau setup-nya ribet setiap mau latihan.

IntervalFit dibuat untuk menyelesaikan masalah itu: timer interval yang cepat disetup, mudah dibaca sambil olahraga, dan punya voice countdown otomatis supaya user tidak perlu lihat layar terus-menerus.

## 2. Tujuan Produk

- User bisa membuat & menjalankan sesi latihan interval (kerja/istirahat) dalam <30 detik setup.
- User tidak perlu memegang/melihat HP terus selama latihan — cukup dengar voice cue.
- Aplikasi bisa dipakai offline, tanpa akun, tanpa biaya.

## 3. Target Pengguna

- Individu yang latihan mandiri (bukan kelas/personal trainer): skipping, lari interval, jalan cepat, atau home workout berbasis waktu.
- Tidak menargetkan atlet kompetitif atau kebutuhan tracking performa mendalam (heart rate, GPS pace, dsb) di v1.

## 4. Ruang Lingkup

### 4.1 In-Scope (v1)
- Timer interval dengan set, durasi kerja, dan durasi istirahat yang bisa diatur bebas.
- Voice countdown "3, 2, 1" otomatis menjelang akhir tiap fase (kerja & istirahat).
- Template workout tersimpan (buat sendiri + beberapa template default).
- Riwayat sesi latihan (tanggal, jenis olahraga, durasi, set selesai).
- Kontrol dasar saat sesi jalan: pause, resume, skip set, stop.
- Berjalan di background (layar mati/app minimized) tanpa timer/voice berhenti.
- Full offline, tanpa akun/login.

### 4.2 Out-of-Scope (v1) — kandidat v2
- Sinkronisasi/cloud backup riwayat antar device.
- Integrasi wearable (smartwatch, heart rate monitor).
- Tracking GPS/pace untuk lari.
- Fitur sosial (share progress, leaderboard, komunitas).
- Rekomendasi/program latihan otomatis (AI coach).

## 5. User Stories

1. **Sebagai** pengguna baru, **saya ingin** langsung pakai template default (misal "Skipping Pemula") **agar** bisa mulai latihan tanpa setup manual.
2. **Sebagai** pengguna, **saya ingin** mengatur jumlah set, durasi kerja, dan durasi istirahat sendiri **agar** sesuai kemampuan/program latihan saya.
3. **Sebagai** pengguna yang sedang lari/skipping, **saya ingin** dengar hitungan mundur "3, 2, 1" sebelum fase berganti **agar** saya tidak perlu lihat layar terus.
4. **Sebagai** pengguna, **saya ingin** HP boleh terkunci/di-lock tapi timer & suara tetap jalan **agar** baterai hemat dan HP aman di kantong/armband.
5. **Sebagai** pengguna, **saya ingin** lihat riwayat latihan saya **agar** bisa pantau konsistensi dari waktu ke waktu.
6. **Sebagai** pengguna, **saya ingin** bisa pause di tengah sesi (misal ada gangguan) **agar** progress tidak hilang.

## 6. Functional Requirements

| ID | Requirement | Prioritas |
|---|---|---|
| FR-1 | User dapat membuat template workout: nama, jenis olahraga, jumlah set, durasi kerja, durasi rest | Must |
| FR-2 | User dapat menjalankan template dan melihat progress visual (ring/bar) + angka detik | Must |
| FR-3 | Sistem memutar voice cue "3, 2, 1" otomatis 3 detik sebelum fase kerja/rest berakhir | Must |
| FR-4 | Timer & voice tetap berjalan saat layar terkunci atau app di background | Must |
| FR-5 | User dapat pause, resume, skip set, dan stop selama sesi berjalan | Must |
| FR-6 | Sistem menyimpan riwayat sesi (selesai penuh maupun berhenti di tengah) | Must |
| FR-7 | Tersedia minimal 2 template default siap pakai | Should |
| FR-8 | User dapat menonaktifkan voice cue (mode senyap/getar saja) | Should |
| FR-9 | User dapat memilih bahasa voice cue (ID/EN) | Could |
| FR-10 | User dapat menambahkan warm-up/cooldown time di template | Could |

## 7. Non-Functional Requirements

- **Akurasi timer**: deviasi maksimal ±0.1 detik dibanding real-time untuk sesi hingga 60 menit.
- **Baterai**: penggunaan background service tidak menguras baterai signifikan (target: <5% per 30 menit sesi aktif).
- **Offline-first**: seluruh fitur inti (FR-1 s/d FR-8) berfungsi tanpa koneksi internet.
- **Platform**: Android dulu di v1 (device penetrasi lebih luas untuk target user awal), iOS menyusul di v1.x — *lihat open question di bawah untuk konfirmasi.*
- **Aksesibilitas**: teks angka besar & kontras tinggi, karena dibaca sambil bergerak.

## 8. Metrik Kesuksesan (v1)

- Waktu dari buka app → sesi mulai berjalan: rata-rata <30 detik (pakai template default/tersimpan).
- Retensi: user kembali menjalankan minimal 1 sesi dalam 7 hari setelah instal (self-tracked, tanpa analytics eksternal dulu di v1).
- Tidak ada laporan timer "meleset"/voice cue telat dari testing manual di device asli.

## 9. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Background execution di-kill OS (terutama Android vendor agresif seperti Xiaomi/Oppo) | Timer/voice berhenti tengah sesi | Riset battery-optimization exemption + foreground service dengan notifikasi persisten |
| TTS on-device kualitas suara tidak konsisten antar merk HP | Pengalaman voice cue kurang baik di sebagian device | Sediakan fallback beep sound, evaluasi opsi audio pre-recorded di v1.x kalau TTS bermasalah |
| Drift akurasi timer karena `Timer.periodic` tidak selalu presisi | Voice cue meleset dari detik sebenarnya | Pakai referensi `DateTime`/`Stopwatch` absolut, bukan hitung mundur dari tick count |

## 10. Open Questions

- [ ] Android-only dulu untuk rilis awal, atau paralel dengan iOS?
- [ ] Voice: TTS on-device atau rekam suara sendiri (kualitas lebih konsisten, effort lebih besar)?
- [ ] Perlu halaman onboarding/tutorial singkat, atau langsung ke home screen?
- [ ] Nama final aplikasi (IntervalFit masih nama kerja)?

## 11. Milestone Kasar

1. **M1** — Timer engine + voice service jalan di dev build (belum ada UI polish).
2. **M2** — UI lengkap (home, buat template, sesi aktif, riwayat).
3. **M3** — Background execution stabil di device fisik.
4. **M4** — Testing manual penuh + fix bug → siap internal use/beta.
