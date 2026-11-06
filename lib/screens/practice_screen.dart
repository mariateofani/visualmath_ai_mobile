import 'package:flutter/material.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';
import '../api.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeState();
}

class _PracticeState extends State<PracticeScreen> {
  String? topicId;
  String difficulty = 'mudah';
  Map<String, dynamic>? remoteQ;
  bool loading = false;
  String? err;
  int? chosenIndex;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    if (app.topics.isNotEmpty) topicId = app.topics.first['id']?.toString();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; err = null; remoteQ = null; chosenIndex = null; answered = false; });
    onlineCheck();
    if (app.online) {
      try {
        final r = await Api.getQuestion(topicId: topicId, difficulty: difficulty);
        if (r != null && r['question'] != null) {
          setState(() { remoteQ = Map<String, dynamic>.from(r['question'] as Map); loading = false; });
          return;
        }
        setState(() { err = (r?['error'] ?? 'Belum ada soal untuk filter ini').toString(); loading = false; });
        return;
      } catch (e) {
        setState(() { err = 'Gagal memuat soal: $e'; loading = false; });
        return;
      }
    }
    // fallback lokal
    final q = app.question;
    setState(() { loading = false; });
  }

  void onlineCheck() async {
    app.online = await (Future.value(true));
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    // Topic options
    final topicOpts = app.topics.isNotEmpty
        ? app.topics
        : [{'id': 'local', 'title': 'Semua topik'}];
    final diffOpts = ['mudah', 'sedang', 'sulit'];

    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Pengaturan latihan'),
        dd('Topik', topicId ?? topicOpts.first['id'].toString(), topicOpts.map((x) => x['id'].toString()).toList(), (v) => setState(() { topicId = v; _load(); })),
        const SizedBox(height: 8),
        dd('Tingkat kesulitan', difficulty, diffOpts, (v) => setState(() { difficulty = v; _load(); })),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: _load, child: const Text('Muat soal baru')),
      ])),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (err != null) msg(context, err!),
      if (!loading && remoteQ != null) _buildRemote(context, t),
      if (!loading && remoteQ == null && err == null) _buildLocal(context, t),
    ]);
  }

  Widget _buildRemote(BuildContext context, Tk t) {
    final q = remoteQ!;
    final prompt = (q['prompt'] ?? q['question'] ?? '').toString();
    final opts = (q['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final expected = (q['expectedAnswer'] ?? '').toString();
    final explanation = (q['explanation'] ?? '').toString();
    final topicTitle = (q['topicTitle'] ?? '').toString();

    return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [pill(topicTitle.isNotEmpty ? topicTitle : difficulty), const SizedBox(width: 8), Expanded(child: muted('Tingkat: $difficulty')), muted('Beruntun ${app.streak}')]),
      const SizedBox(height: 10),
      Text(prompt, style: monoStyle(16).copyWith(height: 1.6)),
      const SizedBox(height: 10),
      if (opts.isEmpty)
        // numeric input fallback
        ...[]
      else
        for (var i = 0; i < opts.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: answered ? null : () => setState(() { chosenIndex = i; answered = true; }),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.all(14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: answered
                      ? (opts[i] == expected ? t.okb : (i == chosenIndex ? t.erb : t.sf))
                      : t.sf,
                  border: Border.all(width: 1.5, color: answered
                      ? (opts[i] == expected ? t.ok : (i == chosenIndex ? t.er : t.ln))
                      : t.ln),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(opts[i], style: monoStyle(16).copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      if (answered) ...[
        const SizedBox(height: 10),
        msg(context, '${chosenIndex != null && opts[chosenIndex!] == expected ? 'Benar!' : 'Belum tepat.'} $explanation', ok: chosenIndex != null && opts[chosenIndex!] == expected),
        const SizedBox(height: 8),
        FilledButton(onPressed: _load, child: const Text('Soal berikutnya')),
      ],
    ]));
  }

  Widget _buildLocal(BuildContext context, Tk t) {
    final q = app.question, a = app.ans;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [pill(q.t), const SizedBox(width: 8), Expanded(child: muted('Level ${q.d} dari 5')), muted('Beruntun ${app.streak}')]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: q.d / 5, minHeight: 8, backgroundColor: t.grid, color: t.ac)),
      const SizedBox(height: 14),
      Text(q.x, style: monoStyle(16).copyWith(height: 1.6)),
      for (var i = 0; i < q.o.length; i++)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: a == null ? () => app.answer(i) : null,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: a == null ? t.sf : q.o[i] == q.ok ? t.okb : i == a ? t.erb : t.sf,
                border: Border.all(width: 1.5, color: a == null ? t.ln : q.o[i] == q.ok ? t.ok : i == a ? t.er : t.ln),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${q.o[i]}', style: monoStyle(16).copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      if (a != null) ...[
        const SizedBox(height: 8),
        msg(context, '${q.o[a] == q.ok ? 'Benar!' : 'Belum tepat.'} ${q.ex}\n${app.lv}', ok: q.o[a] == q.ok),
        FilledButton(onPressed: app.nextQ, child: const Text('Soal berikutnya')),
      ],
    ]));
  }
}
