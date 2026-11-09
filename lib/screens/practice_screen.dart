import 'package:flutter/material.dart';
import '../adaptive.dart';
import '../api.dart';
import '../common.dart';
import '../connectivity.dart';
import '../question_bank.dart';
import '../state.dart';
import '../theme.dart';

/// Latihan adaptif.
///
/// Mode online memakai backend web (soal, penilaian, XP, mastery, dan
/// sertifikat dihitung server). Bila server tidak dapat dihubungi atau sesi
/// login tidak diterima, latihan otomatis beralih ke bank soal lokal dengan
/// aturan adaptif yang sama.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeState();
}

enum _Phase { setup, question, summary }

class _PracticeState extends State<PracticeScreen> {
  // pengaturan
  String topicId = kTopics.first.id;
  String startDifficulty = 'mudah';
  int length = kDefaultSessionLength;

  // sesi
  _Phase phase = _Phase.setup;
  PracticeSession? session;
  PracticeQuestion? q;
  bool online = false;
  String? notice; // info peralihan mode
  bool loading = false;
  String? err;

  // jawaban
  final numCtl = TextEditingController();
  String? choice;
  AnswerOutcome? outcome;
  String? prevDifficulty;
  bool submitting = false;
  DateTime? shownAt;

  // bantuan
  String? hintText;
  bool hintLoading = false;

  // hasil akhir
  Map<String, dynamic>? serverSummary;

  @override
  void dispose() {
    numCtl.dispose();
    super.dispose();
  }

  String _title(String id) => kTopics.firstWhere((t) => t.id == id, orElse: () => kTopics.first).title;

  // ------------------------------------------------------------ alur sesi
  Future<void> _start() async {
    final isOnline = await ConnectivityService.isOnline();
    setState(() {
      session = PracticeSession(topicId: topicId, difficulty: startDifficulty, length: length);
      online = isOnline && app.user != null;
      notice = isOnline ? null : 'Perangkat offline. Latihan memakai bank soal lokal.';
      serverSummary = null;
      phase = _Phase.question;
    });
    await _loadQuestion();
  }

  void _toOffline(String reason) {
    online = false;
    notice = '$reason Latihan dilanjutkan dengan bank soal lokal.';
  }

  Future<void> _loadQuestion() async {
    final s = session!;
    setState(() {
      loading = true;
      err = null;
      q = null;
      outcome = null;
      choice = null;
      hintText = null;
      numCtl.clear();
    });

    if (online) {
      try {
        final r = await Api.getQuestion(topicId: s.topicId, difficulty: s.difficulty, exclude: s.seen.join(','));
        final status = r?['status'] as int? ?? 0;
        if (r != null && r['question'] is Map) {
          final pq = PracticeQuestion.fromServer(Map<String, dynamic>.from(r['question'] as Map), fallbackTopicTitle: _title(s.topicId));
          _show(pq);
          return;
        }
        if (status == 401 || status == 403) {
          _toOffline('Sesi login tidak diterima server.');
        } else {
          _toOffline('Server belum punya soal untuk filter ini.');
        }
      } catch (_) {
        _toOffline('Server tidak dapat dihubungi.');
      }
    }

    final bq = app.practice.pick(s.topicId, s.difficulty, s.seen);
    if (bq == null) {
      setState(() {
        loading = false;
        err = 'Bank soal lokal belum memiliki soal untuk topik ini.';
      });
      return;
    }
    _show(PracticeQuestion.fromBank(bq, _title(s.topicId)));
  }

  void _show(PracticeQuestion pq) {
    session!.seen.add(pq.id);
    setState(() {
      q = pq;
      loading = false;
      shownAt = DateTime.now();
    });
  }

  String get _answerText {
    final pq = q!;
    if (pq.type == 'numeric') return numCtl.text.trim();
    return choice ?? '';
  }

  bool get _canSubmit {
    if (q == null || outcome != null || submitting) return false;
    if (q!.type == 'numeric') return parseNumbers(numCtl.text) != null;
    return choice != null;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final s = session!, pq = q!, ans = _answerText;
    final ms = shownAt == null ? null : DateTime.now().difference(shownAt!).inMilliseconds;
    setState(() {
      submitting = true;
      err = null;
    });

    AnswerOutcome? o;
    if (pq.fromServer) {
      try {
        final r = await Api.answerQuestion(questionId: pq.id, topicId: pq.topicId, sessionId: s.id, answer: ans, timeMs: ms);
        final res = r['result'];
        if (res is Map) {
          o = AnswerOutcome(
            correct: res['correct'] == true,
            expectedAnswer: (res['expectedAnswer'] ?? '').toString(),
            explanation: (res['explanation'] ?? '').toString(),
            nextDifficulty: normalizeDifficulty(res['nextDifficulty']?.toString()),
            xpEarned: (res['xpEarned'] as num?)?.toInt() ?? 0,
            mastery: (res['mastery'] as num?)?.toInt() ?? (r['mastery'] as num?)?.toInt(),
          );
        } else {
          err = (r['error'] ?? 'Jawaban gagal dikirim.').toString();
        }
      } catch (_) {
        err = 'Jawaban gagal dikirim. Periksa koneksi lalu coba lagi.';
      }
    } else {
      final bq = app.practice.byId(pq.id)!;
      final key = topicShort(pq.topicId);
      o = app.practice.grade(bq, ans, alreadyCorrect: app.solvedIds.contains(pq.id), currentMastery: app.mast[key] ?? 0);
    }

    if (!mounted) return;
    if (o == null) {
      setState(() => submitting = false);
      return;
    }
    prevDifficulty = s.difficulty;
    s.record(o);
    app.recordPractice(pq, o);
    setState(() {
      outcome = o;
      submitting = false;
    });
  }

  Future<void> _hint() async {
    final pq = q!;
    setState(() => hintLoading = true);
    String? h;
    if (pq.fromServer) {
      try {
        h = await Api.getHint(questionId: pq.id, topicId: pq.topicId);
      } catch (_) {}
    }
    h ??= pq.hint ?? 'Tuliskan dulu rumus yang relevan, lalu substitusi nilai yang diketahui satu per satu.';
    if (!mounted) return;
    setState(() {
      hintText = h;
      hintLoading = false;
    });
  }

  Future<void> _next() async {
    final s = session!;
    if (s.isComplete) {
      await _finish();
    } else {
      await _loadQuestion();
    }
  }

  Future<void> _finish({bool quit = false}) async {
    final s = session!;
    bool certFromServer = false;
    if (s.answered > 0 && online) {
      try {
        serverSummary = await Api.completeSession(topicId: s.topicId, sessionId: s.id, quit: quit);
        certFromServer = serverSummary?['certificateId'] != null;
      } catch (_) {
        serverSummary = null;
      }
    }
    if (s.answered > 0) app.finishPractice(s, quit: quit, certificateFromServer: certFromServer);
    if (!mounted) return;
    setState(() => phase = s.answered > 0 ? _Phase.summary : _Phase.setup);
  }

  void _reset() => setState(() {
        phase = _Phase.setup;
        session = null;
        q = null;
        outcome = null;
        err = null;
        notice = null;
      });

  // ------------------------------------------------------------ tampilan
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return switch (phase) {
      _Phase.setup => _setupView(context),
      _Phase.question => _questionView(context, t),
      _Phase.summary => _summaryView(context, t),
    };
  }

  Widget _setupView(BuildContext context) {
    final titles = [for (final x in kTopics) x.title];
    final key = topicShort(topicId);
    final count = kQuestionBank.where((x) => x.topicId == topicId).length;
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Pengaturan latihan adaptif'),
        muted('Tingkat soal naik bila jawabanmu benar dan turun bila salah. Skor akhir minimal $kCertificateMinScore memberi sertifikat.'),
        const SizedBox(height: 12),
        dd('Topik', _title(topicId), titles, (v) => setState(() => topicId = kTopics.firstWhere((x) => x.title == v).id)),
        const SizedBox(height: 8),
        dd('Mulai dari tingkat', startDifficulty, kDifficulties, (v) => setState(() => startDifficulty = v)),
        const SizedBox(height: 8),
        dd('Jumlah soal', '$length', const ['5', '10', '15'], (v) => setState(() => length = int.parse(v))),
        const SizedBox(height: 12),
        muted('Penguasaan $key saat ini: ${app.mast[key] ?? 0}%  ·  Bank lokal: $count soal'),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Mulai latihan'))),
      ])),
    ]);
  }

  Widget _questionView(BuildContext context, Tk t) {
    final s = session!;
    final pq = q;
    return page([
      if (notice != null) msg(context, notice!, ok: true),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Soal ${s.answered + (outcome == null ? 1 : 0)} dari ${s.length}', style: const TextStyle(fontWeight: FontWeight.w700))),
          muted('${online ? 'Online' : 'Offline'}  ·  +${s.xp} XP  ·  Beruntun ${s.streak}'),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(value: s.answered / s.length, minHeight: 8, backgroundColor: t.grid, color: t.ac),
        ),
      ])),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      if (err != null) msg(context, err!),
      if (!loading && pq != null) _questionCard(context, t, pq),
      if (!loading && pq == null && err != null)
        FilledButton.tonal(onPressed: _loadQuestion, child: const Text('Coba lagi')),
      TextButton(
        onPressed: submitting ? null : () => _finish(quit: s.answered < s.length),
        child: Text(s.answered == 0 ? 'Batal' : 'Hentikan dan lihat hasil'),
      ),
    ]);
  }

  Widget _questionCard(BuildContext context, Tk t, PracticeQuestion pq) {
    final o = outcome;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, children: [pill(topicShort(pq.topicId)), _diffChip(t, pq.difficulty)]),
      const SizedBox(height: 12),
      Text(pq.prompt, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      if (pq.type == 'numeric') _numericInput(t, pq, o) else _optionList(t, pq, o),
      if (hintText != null && o == null) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.ac2, borderRadius: BorderRadius.circular(12)),
          child: Text('Petunjuk: $hintText', style: TextStyle(color: t.ac, fontWeight: FontWeight.w600)),
        ),
      ],
      const SizedBox(height: 12),
      if (o == null)
        Row(children: [
          OutlinedButton.icon(
            onPressed: hintText != null || hintLoading ? null : _hint,
            icon: hintLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lightbulb_outline),
            label: const Text('Petunjuk'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kirim jawaban'),
            ),
          ),
        ])
      else
        ..._feedback(context, o),
    ]));
  }

  Widget _diffChip(Tk t, String d) {
    final i = kDifficulties.indexOf(d);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(99)),
      child: Text('Tingkat ${i + 1}/3 · $d', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.mu)),
    );
  }

  Widget _numericInput(Tk t, PracticeQuestion pq, AnswerOutcome? o) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: numCtl,
        enabled: o == null,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: monoStyle(16),
        decoration: const InputDecoration(labelText: 'Jawaban', hintText: 'Contoh: 4.4, -0.75, atau 1/3', border: OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: 6),
      muted('Gunakan titik atau koma untuk desimal. Toleransi ±$kNumericTolerance.'),
    ]);
  }

  Widget _optionList(Tk t, PracticeQuestion pq, AnswerOutcome? o) {
    return Column(children: [
      for (final opt in pq.options)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: o == null ? () => setState(() => choice = opt) : null,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: _optColor(t, opt, o, fill: true),
                border: Border.all(width: 1.5, color: _optColor(t, opt, o, fill: false)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(opt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
    ]);
  }

  Color _optColor(Tk t, String opt, AnswerOutcome? o, {required bool fill}) {
    if (o == null) {
      if (opt == choice) return fill ? t.ac2 : t.ac;
      return fill ? t.sf : t.ln;
    }
    final isKey = opt.trim().toLowerCase() == o.expectedAnswer.trim().toLowerCase();
    if (isKey) return fill ? t.okb : t.ok;
    if (opt == choice) return fill ? t.erb : t.er;
    return fill ? t.sf : t.ln;
  }

  List<Widget> _feedback(BuildContext context, AnswerOutcome o) {
    final s = session!;
    final from = prevDifficulty ?? o.nextDifficulty;
    final lv = o.nextDifficulty == from
        ? (o.correct ? 'Tingkat tetap $from (sudah tertinggi).' : 'Tingkat tetap $from (sudah terendah).')
        : (o.correct ? 'Tingkat naik ke ${o.nextDifficulty}.' : 'Tingkat turun ke ${o.nextDifficulty}.');
    final head = o.correct ? 'Benar!${o.xpEarned > 0 ? ' +${o.xpEarned} XP' : ''}' : 'Belum tepat. Jawaban yang benar: ${o.expectedAnswer}';
    return [
      msg(context, '$head\n${o.explanation}', ok: o.correct),
      const SizedBox(height: 8),
      muted('$lv${o.mastery != null ? '  Penguasaan topik: ${o.mastery}%.' : ''}'),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: _next, child: Text(s.isComplete ? 'Lihat hasil' : 'Soal berikutnya')),
      ),
    ];
  }

  Widget _summaryView(BuildContext context, Tk t) {
    final s = session!;
    final score = (serverSummary?['score'] as num?)?.toInt() ?? s.score;
    final total = (serverSummary?['total'] as num?)?.toInt() ?? s.answered;
    final correct = (serverSummary?['correct'] as num?)?.toInt() ?? s.correct;
    final xp = (serverSummary?['xp'] as num?)?.toInt() ?? s.xp;
    final quit = s.answered < s.length;
    final cert = serverSummary?['certificateId'] != null || s.eligibleForCertificate(quit: quit);
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Hasil kuis adaptif'),
        muted(_title(s.topicId)),
        const SizedBox(height: 12),
        Row(children: [stat('$score', 'Skor'), stat('$correct/$total', 'Benar'), stat('+$xp', 'XP')]),
        const SizedBox(height: 12),
        muted('Beruntun terbaik: ${s.bestStreak}  ·  Tingkat akhir: ${s.difficulty}${quit ? '  ·  Sesi dihentikan' : ''}'),
        const SizedBox(height: 12),
        if (cert)
          msg(context, 'Selamat, skor $score memenuhi syarat sertifikat. Lihat di menu Sertifikat.', ok: true)
        else
          msg(context, quit ? 'Sesi dihentikan sebelum selesai, sehingga sertifikat tidak diterbitkan.' : 'Skor minimal $kCertificateMinScore diperlukan untuk sertifikat. Coba lagi dari tingkat mudah.'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: _start, child: const Text('Ulangi topik ini'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonal(onPressed: _reset, child: const Text('Ganti topik'))),
        ]),
      ])),
    ]);
  }
}
