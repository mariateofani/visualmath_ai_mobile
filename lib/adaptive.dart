import 'dart:math';

/// Logika latihan adaptif yang tidak bergantung pada UI.
///
/// Aturan sengaja disamakan dengan backend web (`/api/exercises/answer` dan
/// `/api/exercises/complete`) agar hasil latihan offline dan online konsisten:
/// - tingkat: mudah -> sedang -> sulit; naik bila benar, turun bila salah;
/// - XP per soal benar: mudah 5, sedang 10, sulit 20 (sekali per soal);
/// - perubahan mastery: benar +8/+10/+14, salah -8 (dibatasi 0..100);
/// - jawaban numerik diterima dengan toleransi 0.05;
/// - sertifikat terbit bila skor sesi >= 70 dan sesi tidak dihentikan.

const kDifficulties = ['mudah', 'sedang', 'sulit'];
const kXpPerDifficulty = {'mudah': 5, 'sedang': 10, 'sulit': 20};
const kMasteryGain = {'mudah': 8, 'sedang': 10, 'sulit': 14};
const kMasteryLoss = 8;
const kNumericTolerance = 0.05;
const kCertificateMinScore = 70;
const kDefaultSessionLength = 10;

class TopicInfo {
  final String id, short, title;
  const TopicInfo(this.id, this.short, this.title);
}

class BankQuestion {
  final String id, topicId, difficulty, type, prompt, expectedAnswer, explanation, hint;
  final List<String> options;
  const BankQuestion({
    required this.id,
    required this.topicId,
    required this.difficulty,
    required this.type,
    required this.prompt,
    required this.expectedAnswer,
    required this.options,
    required this.explanation,
    required this.hint,
  });
}

/// Bentuk soal yang dipakai layar latihan, baik dari bank lokal maupun server.
class PracticeQuestion {
  final String id, topicId, topicTitle, difficulty, type, prompt;
  final List<String> options;
  final String? hint;

  /// Hanya terisi untuk soal lokal. Soal dari server tidak membawa kunci.
  final String? expectedAnswer;
  final String? explanation;
  final bool fromServer;

  const PracticeQuestion({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.difficulty,
    required this.type,
    required this.prompt,
    required this.options,
    this.hint,
    this.expectedAnswer,
    this.explanation,
    required this.fromServer,
  });

  factory PracticeQuestion.fromBank(BankQuestion q, String topicTitle) => PracticeQuestion(
        id: q.id,
        topicId: q.topicId,
        topicTitle: topicTitle,
        difficulty: q.difficulty,
        type: q.type,
        prompt: q.prompt,
        options: q.type == 'truefalse' && q.options.isEmpty ? const ['Benar', 'Salah'] : q.options,
        hint: q.hint.isEmpty ? null : q.hint,
        expectedAnswer: q.expectedAnswer,
        explanation: q.explanation,
        fromServer: false,
      );

  /// Membaca objek `question` dari GET /api/exercises.
  factory PracticeQuestion.fromServer(Map<String, dynamic> m, {String fallbackTopicTitle = ''}) {
    final type = (m['type'] ?? 'numeric').toString();
    var opts = (m['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    if (type == 'truefalse' && opts.isEmpty) opts = ['Benar', 'Salah'];
    final title = (m['topicTitle'] ?? '').toString();
    final hint = m['hint']?.toString();
    return PracticeQuestion(
      id: (m['id'] ?? '').toString(),
      topicId: (m['topicId'] ?? '').toString(),
      topicTitle: title.isNotEmpty ? title : fallbackTopicTitle,
      difficulty: normalizeDifficulty(m['difficulty']?.toString()),
      type: type,
      prompt: (m['prompt'] ?? m['question'] ?? '').toString(),
      options: opts,
      hint: (hint == null || hint.isEmpty) ? null : hint,
      fromServer: true,
    );
  }
}

/// Hasil penilaian satu jawaban.
class AnswerOutcome {
  final bool correct;
  final String expectedAnswer;
  final String explanation;
  final String nextDifficulty;
  final int xpEarned;
  final int? mastery;
  const AnswerOutcome({
    required this.correct,
    required this.expectedAnswer,
    required this.explanation,
    required this.nextDifficulty,
    required this.xpEarned,
    this.mastery,
  });
}

String normalizeDifficulty(String? d) => kDifficulties.contains(d) ? d! : 'mudah';

String nextDifficulty(String current, bool correct) {
  final i = kDifficulties.indexOf(normalizeDifficulty(current));
  return kDifficulties[correct ? min(i + 1, 2) : max(i - 1, 0)];
}

int masteryDelta(String difficulty, bool correct, {bool alreadyCorrect = false}) {
  if (!correct) return -kMasteryLoss;
  if (alreadyCorrect) return 0;
  return kMasteryGain[normalizeDifficulty(difficulty)]!;
}

/// Mengubah teks jawaban menjadi daftar angka. Menerima koma desimal
/// ("0,25"), pecahan sederhana ("1/3"), dan beberapa nilai dipisah titik koma.
List<double>? parseNumbers(String raw) {
  final s = raw.trim().replaceAll('−', '-').replaceAll(' ', '');
  if (s.isEmpty) return null;
  final parts = s.contains(';') ? s.split(';') : [s];
  final out = <double>[];
  for (var p in parts) {
    if (p.isEmpty) return null;
    // koma tunggal tanpa titik dianggap pemisah desimal
    if (p.contains(',') && !p.contains('.')) p = p.replaceAll(',', '.');
    if (p.contains('/')) {
      final ab = p.split('/');
      if (ab.length != 2) return null;
      final a = double.tryParse(ab[0]), b = double.tryParse(ab[1]);
      if (a == null || b == null || b == 0) return null;
      out.add(a / b);
    } else {
      final v = double.tryParse(p);
      if (v == null || !v.isFinite) return null;
      out.add(v);
    }
  }
  return out;
}

bool answerMatches(String type, String user, String expected) {
  if (type == 'numeric') {
    final u = parseNumbers(user), e = parseNumbers(expected);
    if (u == null || e == null || u.length != e.length) return false;
    for (var i = 0; i < u.length; i++) {
      if ((u[i] - e[i]).abs() > kNumericTolerance) return false;
    }
    return true;
  }
  return user.trim().toLowerCase() == expected.trim().toLowerCase();
}

/// Mesin latihan lokal (mode offline) di atas bank soal.
class LocalPracticeEngine {
  final List<BankQuestion> bank;
  final Random _rng;
  LocalPracticeEngine(this.bank, {Random? rng}) : _rng = rng ?? Random();

  /// Mengambil soal untuk topik dan tingkat tertentu, menghindari soal yang
  /// sudah muncul di sesi. Bila tingkat itu habis, soal yang sudah muncul boleh
  /// diulang; bila tidak ada sama sekali, dicari di tingkat terdekat.
  BankQuestion? pick(String topicId, String difficulty, Set<String> seen) {
    final order = [difficulty, ...kDifficulties.where((d) => d != difficulty)];
    for (final d in order) {
      final pool = bank.where((q) => q.topicId == topicId && q.difficulty == d).toList();
      if (pool.isEmpty) continue;
      final unseen = pool.where((q) => !seen.contains(q.id)).toList();
      final cand = unseen.isNotEmpty ? unseen : pool;
      return cand[_rng.nextInt(cand.length)];
    }
    return null;
  }

  BankQuestion? byId(String id) {
    for (final q in bank) {
      if (q.id == id) return q;
    }
    return null;
  }

  AnswerOutcome grade(BankQuestion q, String answer, {required bool alreadyCorrect, int currentMastery = 0}) {
    final ok = answerMatches(q.type, answer, q.expectedAnswer);
    final xp = ok && !alreadyCorrect ? kXpPerDifficulty[q.difficulty]! : 0;
    final m = (currentMastery + masteryDelta(q.difficulty, ok, alreadyCorrect: alreadyCorrect)).clamp(0, 100).toInt();
    return AnswerOutcome(
      correct: ok,
      expectedAnswer: q.expectedAnswer,
      explanation: q.explanation,
      nextDifficulty: nextDifficulty(q.difficulty, ok),
      xpEarned: xp,
      mastery: m,
    );
  }
}

/// Status satu sesi latihan (berlaku untuk mode online maupun offline).
class PracticeSession {
  final String id;
  final String topicId;
  final int length;
  String difficulty;
  final Set<String> seen = {};
  int answered = 0, correct = 0, xp = 0, streak = 0, bestStreak = 0;
  bool finished = false;
  final DateTime startedAt = DateTime.now();

  PracticeSession({required this.topicId, required this.difficulty, this.length = kDefaultSessionLength, String? id})
      : id = id ?? _newSessionId();

  int get score => answered == 0 ? 0 : ((correct / answered) * 100).round();
  bool get isComplete => answered >= length;
  bool eligibleForCertificate({bool quit = false}) => !quit && answered > 0 && score >= kCertificateMinScore;

  void record(AnswerOutcome o) {
    answered++;
    if (o.correct) {
      correct++;
      streak++;
      bestStreak = max(bestStreak, streak);
    } else {
      streak = 0;
    }
    xp += o.xpEarned;
    difficulty = o.nextDifficulty;
  }

  static String _newSessionId() {
    final r = Random();
    final rand = List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join();
    return 'm-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-$rand';
  }
}
