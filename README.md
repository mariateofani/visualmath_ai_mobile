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

## Status (jujur)
- Data hanya di memori, hilang saat aplikasi ditutup. Belum terhubung ke backend Node.js/Prisma/JWT.
- Penjelasan AI memakai aturan lokal, bukan LLM/RAG. OCR foto belum ada (hasil bacaan simulasi).
- Indikator offline (NFR-10) belum ada; tambahkan `connectivity_plus` saat integrasi backend.
- Belum dikompilasi di lingkungan pembuatan; jalankan `flutter analyze` dan `flutter test` lebih dulu.

## Langkah integrasi backend
Ganti pemanggilan di `state.dart` (login, register, jawaban) dan `student.dart` (analisis) dengan HTTP ke
`/api/v1/auth/login`, `/api/v1/formulas/validate`, `/api/v1/formulas/explain`, `/api/v1/answers`,
`/api/v1/progress`, `/api/v1/recommendations`.
