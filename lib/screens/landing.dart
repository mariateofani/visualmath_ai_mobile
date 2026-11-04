import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            // Hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.ac, t.ac.withAlpha(180)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.functions, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text('VisualMath AI', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Platform pembelajaran kalkulus peubah banyak berbasis AI.', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 14)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: t.ac),
                  onPressed: () => app.showLogin(),
                  child: const Text('Mulai belajar'),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            Text('Fitur utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.ink)),
            const SizedBox(height: 12),
            _feature(t, Icons.functions, 'AI Math Explainer', 'Solusi langkah demi langkah dengan penjelasan AI.'),
            _feature(t, Icons.show_chart, 'Grafik Interaktif', 'Visualisasi fungsi multivariabel dengan slider parameter.'),
            _feature(t, Icons.edit_note, 'Latihan Adaptif', 'Soal menyesuaikan level kemampuan Anda.'),
            _feature(t, Icons.camera_alt, 'Scan Soal', 'Foto soal, AI baca dan jelaskan.'),
            _feature(t, Icons.emoji_events, 'Sertifikat & Peringkat', 'Dapatkan sertifikat dan bersaing di leaderboard.'),
            _feature(t, Icons.cloud_off, 'Mode Offline', 'Tetap belajar walau tanpa internet.'),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => app.showLogin(), child: const Text('Masuk'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => app.showRegister(), child: const Text('Daftar'))),
            ]),
            const SizedBox(height: 16),
            Center(child: Text('v1.0 • VisualMath AI Mobile', style: TextStyle(color: t.mu, fontSize: 12))),
          ]),
        ),
      ),
    );
  }

  Widget _feature(Tk t, IconData ic, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: t.ac2, borderRadius: BorderRadius.circular(12)),
          child: Icon(ic, color: t.ac, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: t.ink)),
          Text(desc, style: TextStyle(fontSize: 13, color: t.mu)),
        ])),
      ]),
    );
  }
}