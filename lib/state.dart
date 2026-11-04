import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'engine.dart';
import 'api.dart';
import 'storage.dart';
import 'connectivity.dart';

const topik = ['Linear', 'Kuadrat', 'Trigonometri', 'Turunan'];
final _r = Random();
int ri(int a, int b) => a + _r.nextInt(b - a + 1);
String nowS() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

class U {
  int id;
  String nama, email, pw, role, nim;
  bool aktif;
  U(this.id, this.nama, this.email, this.pw, this.role, {this.aktif = true, this.nim = ''});
}

class Mb {
  String n, l;
  int v;
  Mb(this.n, this.v, this.l);
}

class Kls {
  String nama;
  List<Mb> m;
  Kls(this.nama, this.m);
}

class Mat {
  int id;
  String t, tp, k;
  Mat(this.id, this.t, this.tp, this.k);
}

class AiCfg {
  String model = 'LLM Standar', prompt = 'Jelaskan konsep dengan bahasa sederhana, sertakan alasan tiap langkah.';
  double temp = 0.4;
  int limit = 30;
}

class Q {
  final String t, x, ex;
  final int ok, d;
  final List<int> o;
  Q(this.t, this.x, this.ex, this.ok, this.d, this.o);
}

Q genQ(int d) {
  String t = '', x = '', ex = '';
  int ok = 0;
  if (d == 1) {
    t = 'Linear';
    final a = ri(2, 5), b = ri(1, 9), v = ri(1, 5);
    ok = a * v + b;
    x = 'f(x) = ${a}x + $b. Berapa f($v)?';
    ex = 'Substitusi x = $v: $a·$v + $b = $ok.';
  } else if (d == 2) {
    t = 'Linear';
    final a = ri(2, 6), r = ri(1, 6) * (_r.nextBool() ? -1 : 1), b = -a * r;
    ok = r;
    x = '${a}x ${b < 0 ? '−' : '+'} ${b.abs()} = 0. Berapa x?';
    ex = 'x = −b/a = ${-b}/$a = $r.';
  } else if (d == 3) {
    t = 'Kuadrat';
    final p = ri(1, 5), q = p + ri(1, 4);
    ok = q;
    x = 'Akar terbesar dari x² − ${p + q}x + ${p * q} = 0?';
    ex = 'Faktorkan: (x − $p)(x − $q) = 0, sehingga akarnya $p dan $q.';
  } else if (d == 4) {
    if (_r.nextBool()) {
      t = 'Kuadrat';
      final h = ri(1, 5), mm = ri(-5, 5);
      ok = mm;
      x = 'Nilai minimum f(x) = x² − ${2 * h}x + ${h * h + mm} ?';
      ex = 'Bentuk kuadrat sempurna: (x − $h)² + ($mm), minimum bernilai $mm.';
    } else {
      t = 'Turunan';
      final k = ri(2, 4), n = ri(2, 3);
      ok = k * n * (1 << (n - 1));
      x = 'f(x) = ${k}x${n == 2 ? '²' : '³'}. Berapa f′(2)?';
      ex = 'f′(x) = ${k * n}x${n == 2 ? '' : '²'}, sehingga f′(2) = $ok.';
    }
  } else {
    if (_r.nextBool()) {
      t = 'Trigonometri';
      final a = ri(2, 5), c = ri(1, 4);
      ok = a + c;
      x = 'Nilai maksimum y = ${a}sin(x) + $c?';
      ex = 'sin(x) maksimum 1, jadi $a·1 + $c = $ok.';
    } else {
      t = 'Turunan';
      final k = ri(2, 5);
      ok = 3 * k * 4;
      x = 'f(x) = ${k}x³. Berapa f′(2)?';
      ex = 'f′(x) = ${3 * k}x², sehingga f′(2) = ${3 * k}·4 = $ok.';
    }
  }
  final s = <int>{ok};
  var n = 0;
  while (s.length < 4 && n++ < 60) {
    s.add(ok + [-3, -2, -1, 1, 2, 3][ri(0, 5)] * (ok.abs() > 9 ? 2 : 1));
  }
  return Q(t, x, ex, ok, d, s.toList()..shuffle(_r));
}

/// State global sederhana. Semua data di memori (belum terhubung ke backend).
class AppState extends ChangeNotifier {
  U? user;
  String tab = 'home';
  String authView = 'landing';
  bool initializing = false;
  bool online = true;
  int unreadNotif = 0;
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> certificates = [];
  List<Map<String, dynamic>> leaderboard = [];
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> topics = [];
  List<Map<String, dynamic>> usersRemote = [];
  Map<String, dynamic>? aiConfig;
  Map<String, dynamic>? systemInfo;
  final users = <U>[
    U(1, 'Dina Pratama', 'mhs@vma.id', '1234', 'mahasiswa', nim: 'V3925001'),
    U(2, 'Dr. Bagas Wibowo', 'dosen@vma.id', '1234', 'dosen'),
    U(3, 'Admin Prodi', 'admin@vma.id', '1234', 'admin'),
  ];
  String expr = 'a*x^2+b*x+c';
  Map<String, double> p = {'a': 1, 'b': -2, 'c': -3};
  double xr = 6;
  String aiIn = 'y = x^2 - 4x + 3';
  Ex? res;
  String? aiErr, photo;
  final mast = <String, int>{'Linear': 55, 'Kuadrat': 40, 'Trigonometri': 30, 'Turunan': 20};
  int diff = 2, xp = 40, streak = 0, cs = 0;
  Q? q;
  int? ans;
  String lv = '';
  final hist = <String>['Memulai belajar fungsi linear'];
  final logs = <List<String>>[[nowS(), 'Sistem dimulai']];
  final cls = <Kls>[
    Kls('Kalkulus A', [Mb('Dina Pratama', 82, 'Trigonometri'), Mb('Raka Saputra', 68, 'Kuadrat'), Mb('Salsa Putri', 74, 'Trigonometri'), Mb('Bima Aditya', 59, 'Turunan')]),
    Kls('Matematika Dasar B', [Mb('Citra Lestari', 88, 'Linear'), Mb('Dewa Mahendra', 63, 'Kuadrat'), Mb('Eka Wulandari', 71, 'Kuadrat')]),
  ];
  final mat = <Mat>[Mat(1, 'Fungsi Linear dan Gradien', 'Linear', 'Kalkulus A'), Mat(2, 'Akar Persamaan Kuadrat', 'Kuadrat', 'Matematika Dasar B')];
  final ai = AiCfg();

  ThemeMode themeMode = ThemeMode.system;
  void setTheme(ThemeMode m) {
    themeMode = m;
    final v = m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system';
    LocalStore.setThemeMode(v);
    notifyListeners();
  }

  Future<void> init() async {
    // theme
    final tm = await LocalStore.getThemeMode();
    themeMode = tm == 'dark' ? ThemeMode.dark : tm == 'light' ? ThemeMode.light : ThemeMode.system;
    // user cache
    final uj = await LocalStore.getUserJson();
    if (uj != null) {
      try {
        final m = jsonDecode(uj) as Map<String, dynamic>;
        // rebuild a minimal U
        user = U(
          (m['id'] is int) ? m['id'] : int.tryParse('${m['id']}') ?? 0,
          (m['name'] ?? m['nama'] ?? '').toString(),
          (m['email'] ?? '').toString(),
          '',
          (m['role'] ?? 'mahasiswa').toString(),
        );
      } catch (_) {}
    }
    online = await ConnectivityService.isOnline();
    initializing = false;
    notifyListeners();
    // try refresh profile if online
    if (user != null && online) {
      try {
        final p = await Api.me();
        if (p != null) {
          final u = p['user'] ?? p;
          if (u is Map) {
            user = U(
              (u['id'] is int) ? u['id'] : int.tryParse('${u['id']}') ?? user!.id,
              (u['name'] ?? u['nama'] ?? user!.nama).toString(),
              (u['email'] ?? user!.email).toString(),
              '',
              (u['role'] ?? user!.role).toString(),
            );
            await LocalStore.setUserJson(jsonEncode(u));
            notifyListeners();
          }
        }
      } catch (_) {}
    }
    // load notifications count if logged in
    if (user != null) await refreshRemote();
  }

  void showLogin() { authView = 'login'; notifyListeners(); }
  void showRegister() { authView = 'register'; notifyListeners(); }
  void showLanding() { authView = 'landing'; notifyListeners(); }

  Future<void> refreshRemote() async {
    if (user == null) return;
    online = await ConnectivityService.isOnline();
    if (!online) { notifyListeners(); return; }
    try {
      final n = await Api.listNotifications();
      notifications = List<Map<String, dynamic>>.from(n.map((e) => Map<String, dynamic>.from(e as Map)));
      unreadNotif = notifications.where((x) => x['read'] != true && x['isRead'] != true).length;
    } catch (_) {}
    try { materials = List<Map<String, dynamic>>.from((await Api.listMaterials()).map((e) => Map<String, dynamic>.from(e as Map))); } catch (_) {}
    try { classes = List<Map<String, dynamic>>.from((await Api.listClasses()).map((e) => Map<String, dynamic>.from(e as Map))); } catch (_) {}
    try { topics = List<Map<String, dynamic>>.from((await Api.listTopics()).map((e) => Map<String, dynamic>.from(e as Map))); } catch (_) {}
    try { aiConfig = await Api.getAiConfig(); } catch (_) {}
    try { systemInfo = await Api.getSystem(); } catch (_) {}
    if (user!.role == 'admin') {
      try { usersRemote = List<Map<String, dynamic>>.from((await Api.listUsers()).map((e) => Map<String, dynamic>.from(e as Map))); } catch (_) {}
    }
    notifyListeners();
  }

  void upd() => notifyListeners();
  void go(String t) {
    tab = t;
    notifyListeners();
  }

  void addH(String t) => hist.insert(0, '${nowS()} · $t');
  void addL(String t) => logs.insert(0, [nowS(), t]);
  String get lowest => (List.of(topik)..sort((a, b) => mast[a]!.compareTo(mast[b]!))).first;
  final _mail = RegExp(r'^\S+@\S+\.\S+$');

  Future<String?> login(String e, String p) async {
    e = e.trim().toLowerCase();
    if (!_mail.hasMatch(e)) return 'Format email tidak valid.';
    if (p.length < 4) return 'Kata sandi minimal 4 karakter.';
    online = await ConnectivityService.isOnline();
    if (online) {
      try {
        final r = await Api.login(e, p);
        if (r['ok'] == true) {
          final u = r['user'] as Map<String, dynamic>;
          user = U(
            (u['id'] is int) ? u['id'] : int.tryParse('${u['id']}') ?? 0,
            (u['name'] ?? u['nama'] ?? '').toString(),
            (u['email'] ?? e).toString(),
            p,
            (u['role'] ?? 'mahasiswa').toString(),
          );
          tab = 'home';
          authView = 'landing';
          addL('Login: $e');
          await refreshRemote();
          notifyListeners();
          return null;
        }
        return (r['error'] ?? 'Email atau kata sandi salah').toString();
      } catch (_) {
        // fallback offline
      }
    }
    final u = users.where((x) => x.email == e && x.pw == p).firstOrNull;
    if (u == null) return 'Email atau kata sandi salah (offline).';
    if (!u.aktif) return 'Akun ini dinonaktifkan. Hubungi admin.';
    user = u;
    tab = 'home';
    authView = 'landing';
    addL('Login: $e (offline)');
    notifyListeners();
    return null;
  }

  Future<String?> register(String n, String e, String p, String role) async {
    e = e.trim().toLowerCase();
    if (n.trim().length < 3) return 'Nama minimal 3 karakter.';
    if (!_mail.hasMatch(e)) return 'Format email tidak valid.';
    if (p.length < 4) return 'Kata sandi minimal 4 karakter.';
    online = await ConnectivityService.isOnline();
    if (online) {
      try {
        final r = await Api.register(n, e, p, role);
        if (r['ok'] == true) {
          final u = r['user'] as Map<String, dynamic>;
          final nu = U(
            (u['id'] is int) ? u['id'] : int.tryParse('${u['id']}') ?? DateTime.now().millisecondsSinceEpoch,
            (u['name'] ?? n).toString(),
            (u['email'] ?? e).toString(),
            p,
            (u['role'] ?? role).toString(),
          );
          users.add(nu);
          user = nu;
          tab = 'home';
          authView = 'landing';
          addL('Registrasi: $e');
          await refreshRemote();
          notifyListeners();
          return null;
        }
        return (r['error'] ?? 'Registrasi gagal').toString();
      } catch (_) {}
    }
    if (users.any((x) => x.email == e)) return 'Email sudah terdaftar.';
    final u = U(DateTime.now().millisecondsSinceEpoch, n.trim(), e, p, role);
    users.add(u);
    user = u;
    tab = 'home';
    authView = 'landing';
    addL('Registrasi: $e (offline)');
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    addL('Logout: ${user!.email}');
    await Api.logout();
    user = null;
    authView = 'landing';
    tab = 'home';
    notifyListeners();
  }

  Q get question => q ??= genQ(diff);
  void nextQ() {
    q = null;
    ans = null;
    notifyListeners();
  }

  void answer(int i) {
    final qq = question;
    if (ans != null) return;
    ans = i;
    final ok = qq.o[i] == qq.ok;
    if (ok) {
      mast[qq.t] = min(100, mast[qq.t]! + 8);
      streak++;
      xp += 10 * qq.d;
      final n = min(5, diff + 1);
      lv = n > diff ? 'Level soal naik ke $n.' : 'Level soal sudah maksimal.';
      diff = n;
    } else {
      mast[qq.t] = max(0, mast[qq.t]! - 6);
      streak = 0;
      final n = max(1, diff - 1);
      lv = n < diff ? 'Level soal turun ke $n.' : 'Level soal tetap di dasar.';
      diff = n;
    }
    addH('Latihan ${qq.t}: ${ok ? 'benar' : 'salah'} (level ${qq.d})');
    notifyListeners();
  }
}

final app = AppState();
