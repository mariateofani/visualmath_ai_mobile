import 'package:flutter/material.dart';
import 'common.dart';
import 'screens/auth.dart';
import 'screens/certificates.dart';
import 'screens/landing.dart';
import 'screens/leaderboard.dart';
import 'screens/notifications.dart';
import 'screens/staff.dart';
import 'screens/student.dart';
import 'state.dart';
import 'theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity.dart';

void main() => runApp(const VisualMathApp());

class VisualMathApp extends StatefulWidget {
  const VisualMathApp({super.key});
  @override
  State<VisualMathApp> createState() => _VisualMathAppState();
}

class _VisualMathAppState extends State<VisualMathApp> {
  bool _online = true;
  @override
  void initState() {
    super.initState();
    ConnectivityService.isOnline().then((v) => setState(() => _online = v));
    ConnectivityService.onChanges.listen((r) => setState(() => _online = r.isNotEmpty && !r.contains(ConnectivityResult.none)));
    app.init();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: app,
      builder: (_, __) => MaterialApp(
        title: 'VisualMath AI',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.themeMode,
        builder: (c, child) => ColoredBox(
          color: Theme.of(c).scaffoldBackgroundColor,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(children: [
                OfflineBanner(online: _online),
                Expanded(child: child ?? const SizedBox.shrink()),
              ]),
            ),
          ),
        ),
        home: ListenableBuilder(listenable: app, builder: (_, __) {
          if (app.initializing) return const _Splash();
          if (app.user == null) {
            switch (app.authView) {
              case 'login': return const LoginScreen();
              case 'register': return const LoginScreen(startRegister: true);
              default: return const LandingScreen();
            }
          }
          return Shell();
        }),
      ));
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.functions, size: 64, color: t.ac),
          const SizedBox(height: 16),
          Text('VisualMath AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.ink)),
          const SizedBox(height: 24),
          CircularProgressIndicator(color: t.ac),
        ]),
      ),
    );
  }
}

const _nav = {
  'mahasiswa': [('home', Icons.home_rounded, 'Beranda'), ('ai', Icons.functions_rounded, 'AI Math'), ('graf', Icons.show_chart_rounded, 'Grafik'), ('lat', Icons.edit_note_rounded, 'Latihan'), ('me', Icons.person_rounded, 'Saya')],
  'dosen': [('home', Icons.home_rounded, 'Beranda'), ('mat', Icons.menu_book_rounded, 'Materi'), ('kls', Icons.groups_rounded, 'Kelas'), ('me', Icons.person_rounded, 'Profil')],
  'admin': [('home', Icons.home_rounded, 'Beranda'), ('usr', Icons.manage_accounts_rounded, 'Pengguna'), ('cfg', Icons.tune_rounded, 'AI & Log'), ('me', Icons.person_rounded, 'Profil')],
};
const _ttl = {'home': 'Beranda', 'ai': 'AI Math Explainer', 'graf': 'Grafik & Simulasi', 'lat': 'Latihan Adaptif', 'me': 'Profil', 'mat': 'Materi & Soal', 'kls': 'Kelas', 'usr': 'Pengguna & Role', 'cfg': 'Konfigurasi & Monitoring', 'notif': 'Notifikasi', 'sert': 'Sertifikat', 'rank': 'Peringkat'};

class Shell extends StatelessWidget {
  Shell({super.key});

  Widget _body(String role) {
    switch (app.tab) {
      case 'home': return role == 'mahasiswa' ? StudentHome() : role == 'dosen' ? TeacherHome() : AdminHome();
      case 'ai': return AiScreen();
      case 'graf': return GraphScreen();
      case 'lat': return PracticeScreen();
      case 'mat': return MaterialScreen();
      case 'kls': return ClassScreen();
      case 'usr': return UsersScreen();
      case 'cfg': return ConfigScreen();
      case 'notif': return NotificationsScreen();
      case 'sert': return CertificatesScreen();
      case 'rank': return LeaderboardScreen();
      default: return ProfileScreen();
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
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: Text(_ttl[app.tab] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () => app.go('notif'), icon: Badge.count(count: app.unreadNotif, child: const Icon(Icons.notifications_outlined))),
          const ThemeBtn(),
          Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: pill(role))),
        ],
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