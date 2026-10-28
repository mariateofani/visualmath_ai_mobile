import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../common.dart';
import '../engine.dart';
import '../state.dart';
import '../theme.dart';

Compiled? _try(String s) {
  try {
    return compile(s);
  } on MathErr {
    return null;
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});
  @override
  Widget build(BuildContext context) {
    final c = _try(app.expr), w = app.lowest;
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Halo, ${app.user!.nama.split(" ").first}'),
        muted('Lanjutkan dari grafik terakhirmu.'),
        const SizedBox(height: 10),
        if (c != null) PlotView(c: c, p: app.p, xr: app.xr, ratio: 2.27, mini: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => app.go('graf'), child: const Text('Buka simulasi'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonal(onPressed: () => app.go('ai'), child: const Text('Input rumus'))),
        ]),
      ])),
      Row(children: [stat('${app.xp}', 'XP'), stat('${app.diff}/5', 'Level soal'), stat('${app.streak}', 'Beruntun')]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h3('Penguasaan topik'), for (final t in topik) bar(t, app.mast[t]!)])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Rekomendasi AI'),
        Text('Topik $w paling perlu diperkuat (${app.mast[w]}%). Kerjakan latihan level ${(app.diff - 1).clamp(1, 5)} untuk membangun dasar.'),
        const SizedBox(height: 10),
        FilledButton.tonal(onPressed: () => app.go('lat'), child: const Text('Mulai latihan')),
      ])),
    ]);
  }
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiState();
}

class _AiState extends State<AiScreen> {
  late final tc = TextEditingController(text: app.aiIn);
  bool busy = false;

  Future<void> run() async {
    Compiled c;
    try {
      c = compile(app.aiIn);
    } on MathErr catch (e) {
      setState(() {
        app.aiErr = e.msg;
        app.res = null;
      });
      return;
    }
    setState(() {
      busy = true;
      app.aiErr = null;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    final r = explain(c, {'a': 1, 'b': 1, 'c': 0});
    app.xp += 5;
    app.addH('Menganalisis: ${app.aiIn.trim()}');
    app.addL('AI Explainer dipanggil');
    if (!mounted) return;
    setState(() {
      app.res = r;
      busy = false;
    });
  }

  Future<void> scan() async {
    final src = await showDialog<ImageSource>(
      context: context,
      builder: (_) => SimpleDialog(title: const Text('Foto soal'), children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text('Ambil dengan kamera')),
        SimpleDialogOption(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text('Pilih dari galeri')),
      ]),
    );
    if (src == null) return;
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 1280);
      if (f == null) return;
      setState(() {
        app.photo = f.path;
        app.aiIn = 'y = 2x^2 - 8x + 6';
        tc.text = app.aiIn;
      });
      app.addH('Mengunggah foto soal');
    } catch (_) {
      if (mounted) snack(context, 'Kamera atau galeri tidak dapat dibuka');
    }
  }

  void sim(Ex r) {
    final a = r.a;
    final c = compile(app.aiIn);
    if (a.type == 'lin') {
      app.expr = 'a*x+b';
      app.p = {'a': a.b, 'b': a.c, 'c': 0};
    } else if (a.type == 'quad') {
      app.expr = 'a*x^2+b*x+c';
      app.p = {'a': a.a, 'b': a.b, 'c': a.c};
    } else {
      app.expr = c.src;
    }
    app.go('graf');
  }

  @override
  Widget build(BuildContext context) {
    final r = app.res;
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        field(tc, 'Rumus atau soal', mono: true, lines: 2, onChanged: (v) => app.aiIn = v),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final x in ['y = 2x + 3', 'y = x^2 - 4x + 3', 'y = 2sin(x) + 1', 'y = 2x +'])
            ActionChip(label: Text(x, style: monoStyle(13)), onPressed: () => setState(() {
                  app.aiIn = x;
                  tc.text = x;
                })),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FilledButton.tonal(onPressed: scan, child: const Text('Foto soal'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: busy ? null : run, child: const Text('Analisis'))),
        ]),
      ])),
      if (app.photo != null)
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(app.photo!, height: 180, width: double.infinity, fit: BoxFit.contain) : Image.file(File(app.photo!), height: 180, width: double.infinity, fit: BoxFit.contain)),
          const SizedBox(height: 8),
          muted('Hasil bacaan (simulasi, belum tersambung ke OCR) sudah diisi di kolom rumus. Periksa dan edit sebelum dianalisis.'),
        ])),
      if (busy) const Center(child: CircularProgressIndicator()),
      if (app.aiErr != null) msg(context, app.aiErr!),
      if (r != null && !busy) ...[
        msg(context, 'Format rumus valid. Hasil dihitung oleh mesin matematika.', ok: true),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h3('Penjelasan konsep'),
          for (final x in r.k) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $x')),
          const Divider(),
          h3('Langkah penyelesaian'),
          for (var i = 0; i < r.l.length; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('${i + 1}. ${r.l[i]}')),
          const Divider(),
          h3('Contoh penerapan nyata'),
          Text(r.h),
        ])),
        FilledButton(onPressed: () => sim(r), child: const Text('Lihat grafik dan simulasi')),
      ],
    ]);
  }
}

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});
  @override
  State<GraphScreen> createState() => _GraphState();
}

class _GraphState extends State<GraphScreen> {
  late final tc = TextEditingController(text: app.expr);

  @override
  Widget build(BuildContext context) {
    Compiled? c;
    String? err;
    try {
      c = compile(app.expr);
    } on MathErr catch (e) {
      err = e.msg;
    }
    final ks = c == null ? <String>[] : ['a', 'b', 'c'].where(c.used.contains).toList();
    List<double> ro = [];
    double y0 = 0;
    if (c != null) {
      final g = analyze(c, app.p).g;
      ro = roots(g);
      y0 = g(0);
    }
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        field(tc, 'Rumus f(x)', mono: true, onChanged: (v) => setState(() => app.expr = v)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final x in const {'Linear': 'a*x+b', 'Kuadrat': 'a*x^2+b*x+c', 'Trigonometri': 'a*sin(b*x)+c'}.entries)
            ActionChip(label: Text(x.key), onPressed: () => setState(() {
                  app.expr = x.value;
                  tc.text = x.value;
                })),
        ]),
      ])),
      if (err != null) msg(context, err),
      if (c != null) PlotView(c: c, p: app.p, xr: app.xr, ratio: 1.31),
      Row(children: [
        ActionChip(label: const Text('Perbesar'), onPressed: () => setState(() => app.xr = (app.xr - 2).clamp(2.0, 20.0).toDouble())),
        const SizedBox(width: 8),
        ActionChip(label: const Text('Perkecil'), onPressed: () => setState(() => app.xr = (app.xr + 2).clamp(2.0, 20.0).toDouble())),
        const SizedBox(width: 8),
        ActionChip(label: const Text('Reset'), onPressed: () => setState(() => app.p = {'a': 1, 'b': 1, 'c': 0})),
      ]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Simulasi parameter'),
        if (ks.isEmpty) const Text('Tambahkan a, b, atau c pada rumus agar bisa diatur dengan slider.'),
        for (final k in ks)
          Row(children: [
            SizedBox(width: 20, child: Text(k, style: monoStyle(14).copyWith(fontWeight: FontWeight.w800))),
            Expanded(child: Slider(min: -5, max: 5, divisions: 100, value: (app.p[k] ?? 0).clamp(-5.0, 5.0).toDouble(), onChanged: (v) => setState(() => app.p[k] = double.parse(v.toStringAsFixed(1))))),
            SizedBox(width: 44, child: Text(fm(app.p[k] ?? 0), textAlign: TextAlign.right)),
          ]),
      ])),
      if (c != null)
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h3('Titik penting'),
          Text('Titik potong sumbu y: (0, ${fm(y0)})'),
          Text('Titik potong sumbu x: ${ro.isEmpty ? 'tidak ditemukan pada −10 sampai 10' : ro.map((x) => '(${fm(x)}, 0)').join(', ')}'),
        ])),
    ]);
  }
}

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final q = app.question, a = app.ans, t = tk(context);
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ])),
      if (a != null) ...[
        msg(context, '${q.o[a] == q.ok ? 'Benar!' : 'Belum tepat.'} ${q.ex}\n${app.lv}', ok: q.o[a] == q.ok),
        FilledButton(onPressed: app.nextQ, child: const Text('Soal berikutnya')),
      ],
    ]);
  }
}
