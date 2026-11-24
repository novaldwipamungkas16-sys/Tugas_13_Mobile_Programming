# Tugas 13 — Mobile Programming (Teori)

**noval dwi pamungkas — 240605110040**

Repository: https://github.com/novaldwipamungkas16-sys/Tugas_13_Mobile_Programming

```bash
git clone https://github.com/novaldwipamungkas16-sys/Tugas_13_Mobile_Programming.git
cd Tugas_13_Mobile_Programming/lkm_pendataan_mahasiswa
```

Source code dan tes diunggah ke repository. APK, screenshot, serta LKM merupakan berkas penyerahan lokal terpisah; bukan bagian unggahan source ini.

## Output utama LKM 13

- `LKM_Flutter_Firebase_Login_Hak_Akses_Pendataan_Mahasiswa.docx`: LKM asli dosen, dipertahankan tanpa perubahan.
- `LKM_13_Hasil_Pengerjaan.docx` dan `LKM_13_Hasil_Pengerjaan.pdf`: hasil pengerjaan LKM 13; bukan laporan BAB I–VI.
- `build/app-release.apk` dan `build/app-debug.apk`: APK hasil build teruji.
- `documentation/laporan_praktikum.*`: arsip keluaran lama, **bukan output utama pengumpulan**. Audit laporan lama hanya berlaku pada revisi arsip tersebut.

Seluruh source aplikasi, Rules, skrip admin, suite tes, APK, dan bukti berada dalam folder teori ini. Identitas yang belum diberikan tetap placeholder.

Flutter + Firebase Authentication + Cloud Firestore. Acuan utama: LKM Login & Hak Akses, versi 1.0, 18 November 2026. Status: SELESAI DENGAN CATATAN; backend dan alur UI utama Pixel_5 teruji. Identitas laporan perlu diisi mahasiswa.

## Proyek

- Firebase: `lkm-mahasiswa-t13-noval`, Spark tanpa billing.
- Android package: `com.example.lkm_pendataan_mahasiswa`.
- Firestore: `(default)`, `asia-southeast2`, free tier.
- Provider Email/Password dan Anonymous aktif, dibaca balik melalui API.
- Flutter 3.47.2 / Dart 3.13.2; Node 24.22.0; Firebase CLI 15.34.2.

## Menjalankan

Dari `lkm_pendataan_mahasiswa`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

Konfigurasi `lib/firebase_options.dart` dihasilkan FlutterFire untuk proyek tersebut; bukan kredensial admin. Pada terminal Windows lokal, Flutter SDK tersedia di `D:/src/flutter/bin`. Target Android membutuhkan perangkat USB debugging atau emulator. Browser web merupakan target tambahan, bukan pengganti verifikasi Android.

## Struktur

- `lkm_pendataan_mahasiswa/lib/`: aplikasi modular, satu halaman per file.
- `lkm_pendataan_mahasiswa/test/`: validasi, dropdown, konfirmasi logout, isolasi route sesi.
- `firestore.rules` dan `firebase.json` di **root tugas**: Rules dan Emulator Suite; berbeda dari firebase.json hasil FlutterFire dalam folder aplikasi.
- `admin-tools/`: skrip claim tepercaya; lihat README di folder tersebut.
- `security-tests/`: Rules dan claim integration tests.
- `documentation/`: jawaban latihan, hasil pengujian, refleksi, panduan demo, bukti JSON/log.

## Roles dan skema

Admin ditentukan oleh `admin == true` pada custom claim token. User non-anonim hanya mengakses profil `mahasiswa/{UID}`; NIM, ownerUid, dan createdAt tidak boleh diubah sendiri. Tamu hanya informasi umum dan ditolak mengakses koleksi. Arsip admin menggunakan auto-ID dan ownerUid kosong. Field dokumen: ownerUid, nim, nama, prodi, angkatan, createdAt, updatedAt. NIM belum dijamin unik global.

## Uji Rules

Dari root tugas:

```bash
npm --prefix security-tests ci
npm --prefix admin-tools ci
firebase emulators:exec --project demo-lkm-mahasiswa-t13 --only auth,firestore --config firebase.json "npm --prefix security-tests test"
```

Gunakan Java yang sesuai Emulator Suite; host pengujian memakai JBR Android Studio. Jangan mengganti project demo dengan proyek nyata pada skrip emulator. Deployment Rules dilakukan dari root tugas:

```bash
firebase deploy --only firestore:rules --project lkm-mahasiswa-t13-noval --config firebase.json
```

## Bukti dan batasan

10 tes Flutter lulus; analyze tanpa masalah. Emulator: 69 pemeriksaan Rules dan 4 pemeriksaan claim lulus. Firebase nyata: 20 pemeriksaan klien lulus, meliputi T02–T12 dan pergantian sesi admin ke anonim. Sumber Rules produksi dibandingkan dengan lokal dan cocok. Debug APK berhasil dibangun setelah pengurangan heap/worker dan penonaktifan Kotlin incremental untuk cache lintas drive. Build release berhasil; APK tersedia di lkm_pendataan_mahasiswa/build/app/outputs/flutter-apk/app-release.apk.

T01 end-to-end, UI profil mahasiswa, CRUD arsip admin, dan admin logout ke tamu lulus pada Pixel_5. Bukti: documentation/device_results.json dan documentation/screenshots. Laporan DOCX/PDF tersedia; PDF utama dibuat ReportLab (19 halaman); DOCX juga dirender melalui Microsoft Word dan 23/23 halaman ditinjau visual. Kedua format memuat 20 screenshot asli ber-caption serta lampiran ALLOW/DENY dari JSON aktual; lihat documentation/report_layout_audit.md. Akun otomatis backend memakai password acak yang tidak disimpan; jangan menganggapnya akun siap presentasi. Akun demonstrasi tersendiri sudah dibuat dan diuji pada Pixel_5; claim admin pada UID yang diotorisasi sudah diverifikasi. Kredensial dimasukkan pengguna langsung dan tidak disimpan dalam laporan. Jangan menambahkan service account, token, password, atau data mahasiswa nyata ke repository. Repository belum dipublikasikan.
