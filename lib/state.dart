import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'engine.dart';
import 'adaptive.dart';
import 'question_bank.dart';
import 'api.dart';
import 'storage.dart';
import 'connectivity.dart';

/// Nama pendek delapan topik kalkulus peubah banyak (sama dengan backend web).
final topik = [for (final t in kTopics) t.short];

String topicShort(String topicId) => kTopics.firstWhere((t) => t.id == topicId, orElse: () => const TopicInfo('', 'Umum', 'Umum')).short;
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
  /// Penguasaan (0..100) per topik, dikunci dengan nama pendek topik.
  final mast = <String, int>{for (final t in kTopics) t.short: 0};
  int correctCount = 0;
  /// Tingkat latihan terakhir: 1 = mudah, 2 = sedang, 3 = sulit.
  int diff = 1, xp = 0, streak = 0, cs = 0;
  /// Soal yang pernah dijawab benar (anti-farming XP, sama seperti web).
  final solvedIds = <String>{};
  final practice = LocalPracticeEngine(kQuestionBank);
  final hist = <String>['Memulai belajar kalkulus peubah banyak'];
  final logs = <List<String>>[[nowS(), 'Sistem dimulai']];
  final cls = <Kls>[
    Kls('Kalkulus A', [Mb('Dina Pratama', 82, 'Limit & Kontinuitas'), Mb('Raka Saputra', 68, 'Aturan Rantai'), Mb('Salsa Putri', 74, 'Optimasi'), Mb('Bima Aditya', 59, 'Integral Lipat Dua')]),
    Kls('Matematika Dasar B', [Mb('Citra Lestari', 88, 'Koordinat & Fungsi'), Mb('Dewa Mahendra', 63, 'Turunan Parsial'), Mb('Eka Wulandari', 71, 'Integral Lipat Tiga')]),
  ];
  final mat = <Mat>[Mat(1, 'Gradien dan Turunan Berarah', 'Turunan Parsial', 'Kalkulus A'), Mat(2, 'Integral Lipat Dua: Dasar', 'Integral Lipat Dua', 'Matematika Dasar B')];
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

  void issueCertificate(String title, int score) {
    certificates.add({'title': title, 'issued': DateTime.now().toIso8601String().substring(0, 10), 'score': score});
    addH('Sertifikat diperoleh: $title');
    addL('Sertifikat: $title');
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

  /// Mencatat hasil satu jawaban latihan ke state lokal (progres, XP, riwayat).
  void recordPractice(PracticeQuestion q, AnswerOutcome o) {
    final key = topicShort(q.topicId);
    if (o.mastery != null) {
      mast[key] = o.mastery!.clamp(0, 100).toInt();
    } else {
      final already = solvedIds.contains(q.id);
      mast[key] = ((mast[key] ?? 0) + masteryDelta(q.difficulty, o.correct, alreadyCorrect: already)).clamp(0, 100).toInt();
    }
    if (o.correct) {
      solvedIds.add(q.id);
      streak++;
    } else {
      streak = 0;
    }
    xp += o.xpEarned;
    diff = kDifficulties.indexOf(o.nextDifficulty) + 1;
    addH('Latihan $key: ${o.correct ? 'benar' : 'salah'} (tingkat ${q.difficulty})');
    notifyListeners();
  }

  /// Menutup sesi: catat riwayat dan terbitkan sertifikat bila memenuhi syarat.
  void finishPractice(PracticeSession s, {bool quit = false, bool certificateFromServer = false}) {
    if (s.finished) return;
    s.finished = true;
    final key = topicShort(s.topicId);
    addH('Kuis adaptif $key: skor ${s.score} (${s.correct}/${s.answered}) +${s.xp} XP${quit ? ' (dihentikan)' : ''}');
    if (certificateFromServer || s.eligibleForCertificate(quit: quit)) {
      final title = 'Kuis Adaptif $key';
      final idx = certificates.indexWhere((c) => c['title'] == title);
      if (idx < 0) {
        issueCertificate(title, s.score);
      } else if ((certificates[idx]['score'] as int? ?? 0) < s.score) {
        certificates[idx] = {...certificates[idx], 'score': s.score, 'issued': DateTime.now().toIso8601String().substring(0, 10)};
      }
    }
    notifyListeners();
  }
}

final app = AppState();
