import 'package:flutter/material.dart';
import 'common.dart';
import 'screens/auth.dart';
import 'screens/staff.dart';
import 'screens/student.dart';
import 'state.dart';
import 'theme.dart';

void main() => runApp(const VisualMathApp());

class VisualMathApp extends StatelessWidget {
  const VisualMathApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VisualMath AI',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        // Kolom maksimal 480 px di tengah, seperti versi HTML.
        builder: (c, child) => ColoredBox(
          color: Theme.of(c).scaffoldBackgroundColor,
          child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child)),
        ),
        // Penting: jangan pakai const di sini, agar layar ikut dibangun ulang saat state berubah.
        home: ListenableBuilder(listenable: app, builder: (_, __) => app.user == null ? LoginScreen() : Shell()),
      );
}

const _nav = {
  'mahasiswa': [('home', Icons.home_outlined, 'Beranda'), ('ai', Icons.functions, 'AI Math'), ('graf', Icons.show_chart, 'Grafik'), ('lat', Icons.edit_note, 'Latihan'), ('me', Icons.person_outline, 'Saya')],
  'dosen': [('home', Icons.home_outlined, 'Beranda'), ('mat', Icons.menu_book_outlined, 'Materi'), ('kls', Icons.groups_outlined, 'Kelas'), ('me', Icons.person_outline, 'Profil')],
  'admin': [('home', Icons.home_outlined, 'Beranda'), ('usr', Icons.manage_accounts_outlined, 'Pengguna'), ('cfg', Icons.tune, 'AI & Log'), ('me', Icons.person_outline, 'Profil')],
};
const _ttl = {'home': 'Beranda', 'ai': 'AI Math Explainer', 'graf': 'Grafik & Simulasi', 'lat': 'Latihan Adaptif', 'me': 'Profil', 'mat': 'Materi & Soal', 'kls': 'Kelas', 'usr': 'Pengguna & Role', 'cfg': 'Konfigurasi & Monitoring'};

class Shell extends StatelessWidget {
  Shell({super.key});

  Widget _body(String role) {
    switch (app.tab) {
      case 'home':
        return role == 'mahasiswa' ? StudentHome() : role == 'dosen' ? TeacherHome() : AdminHome();
      case 'ai':
        return AiScreen();
      case 'graf':
        return GraphScreen();
      case 'lat':
        return PracticeScreen();
      case 'mat':
        return MaterialScreen();
      case 'kls':
        return ClassScreen();
      case 'usr':
        return UsersScreen();
      case 'cfg':
        return ConfigScreen();
      default:
        return ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = app.user!.role, items = _nav[role]!, t = tk(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.sf,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: t.ln)),
        titleSpacing: 16,
        title: Text(_ttl[app.tab] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: pill(role)))],
      ),
      body: SafeArea(bottom: false, child: _body(role)),
      bottomNavigationBar: _BottomNav(items: items, cur: app.tab),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<(String, IconData, String)> items;
  final String cur;
  const _BottomNav({required this.items, required this.cur});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      decoration: BoxDecoration(color: t.sf, border: Border(top: BorderSide(color: t.ln))),
      padding: const EdgeInsets.all(6),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (final e in items)
            Expanded(
              child: Material(
                color: e.$1 == cur ? t.ac2 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => app.go(e.$1),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(e.$2, size: 22, color: e.$1 == cur ? t.ac : t.mu),
                      Text(e.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: e.$1 == cur ? t.ac : t.mu)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
