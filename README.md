# VisualMath AI Mobile (Flutter)

Frontend mobile untuk sistem **VisualMath AI** (SKPL FR-01 s.d. FR-19), dibuat dengan Flutter dan Material 3.
Hanya memakai satu paket tambahan: `image_picker` (foto soal).

## Fitur
- **Mahasiswa**: registrasi/login, input rumus + validasi, foto soal, AI Math Explainer (konsep, langkah, contoh nyata),
  grafik interaktif + slider parameter, latihan adaptif, dashboard, progres, riwayat, profil.
- **Dosen**: dashboard kelas (jumlah, rata-rata, materi tersulit), CRUD materi, manajemen kelas dan anggota.
- **Admin**: manajemen pengguna/role (aktif/nonaktif/hapus), konfigurasi AI, log aktivitas.

## Cara menjalankan di Android Studio
1. Pasang **Flutter SDK** (>= 3.19, Dart >= 3.3) dan **Android Studio** + plugin **Flutter** dan **Dart**.
2. Ekstrak zip ini, lalu di terminal masuk ke folder `visualmath_ai`.
3. Buat folder platform Android (belum disertakan di zip):
   ```
   flutter create --platforms=android --project-name visualmath_ai --org id.ac.uns.visualmath .
   ```
   Perintah ini hanya menambah file yang belum ada (folder `android/` dll). Jika `lib/main.dart`
   atau `test/widget_test.dart` tertimpa, ekstrak ulang kedua file itu dari zip.
4. `flutter pub get`
5. Buka folder di Android Studio (**File > Open**), pilih emulator atau HP (USB debugging), klik **Run**.
   Atau: `flutter run`.
6. Build APK: `flutter build apk --release`

Akun contoh (kata sandi `1234`): `mhs@vma.id`, `dosen@vma.id`, `admin@vma.id`.

## Struktur
```
lib/
  main.dart          tema, navigasi bawah per peran
  state.dart         state global (ChangeNotifier), model, generator soal, login
  engine.dart        parser ekspresi, analisis, akar, penjelasan berbasis aturan
  common.dart        widget bersama, PlotPainter (CustomPainter), profil
  screens/auth.dart  login/daftar
  screens/student.dart  beranda, AI Math, grafik, latihan
  screens/staff.dart    dosen dan admin
```

## Latihan adaptif

- **Mode online** memakai backend web: `GET /api/exercises`, `POST /api/exercises/answer`,
  `POST /api/exercises/hint`, dan `POST /api/exercises/complete`. Penilaian, XP, mastery, dan
  sertifikat dihitung server. Token sesi diambil dari cookie `vma_session` saat login dan dikirim
  kembali sebagai header `Cookie` (backend web hanya membaca cookie).
- **Mode offline** (atau bila server menolak sesi / tidak punya soal) memakai bank soal lokal
  `lib/question_bank.dart`: 96 soal orisinal, 8 topik kalkulus peubah banyak x 3 tingkat x 4 soal,
  tipe isian numerik, pilihan ganda, dan benar/salah.
- Aturan adaptif disamakan dengan web (`lib/adaptive.dart`): tingkat naik bila benar dan turun bila
  salah; XP 5/10/20 sekali per soal; mastery +8/+10/+14 atau -8; toleransi numerik 0.05; sertifikat
  bila skor sesi >= 70 dan sesi tidak dihentikan.
- Sumber soal: disusun tim mengikuti cakupan OpenStax *Calculus Volume 3* (Strang & Herman,
  CC BY-NC-SA 4.0) bab 2-5. Kunci numerik diverifikasi numerik oleh `tool/bank.py`.
  Untuk menambah soal: ubah `tool/bank.py`, lalu jalankan
  `python3 tool/bank.py lib/question_bank.dart` (skrip menolak menulis bila ada kunci yang salah).
- Uji unit: `flutter test test/adaptive_test.dart`.

## Status (jujur)
- Perubahan latihan adaptif belum dikompilasi di lingkungan pembuatnya (Flutter SDK tidak tersedia);
  jalankan `flutter analyze` dan `flutter test` lebih dulu.
- Mode online pada Flutter Web bergantung pada pengaturan cookie/CORS browser; target utama Android.
- Penjelasan AI di layar AI Math masih memakai aturan lokal, belum LLM/RAG dari server.
