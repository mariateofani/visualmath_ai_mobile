import 'dart:math';
import 'package:flutter/material.dart';
import 'engine.dart';
import 'state.dart';
import 'theme.dart';

Widget page(List<Widget> ch) => ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final w in ch) Padding(padding: const EdgeInsets.only(bottom: 14), child: w)],
    );

Widget card(Widget child) => Builder(builder: (c) {
      final t = tk(c);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: t.sf, border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(16)),
        child: child,
      );
    });

Widget h3(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)));

Widget muted(String s) => Builder(builder: (c) => Text(s, style: TextStyle(fontSize: 13, color: tk(c).mu)));

Widget pill(String s) => Builder(builder: (c) {
      final t = tk(c);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: t.ac2, borderRadius: BorderRadius.circular(99)),
        child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.ac)),
      );
    });

Widget msg(BuildContext c, String s, {bool ok = false}) {
  final t = tk(c);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: ok ? t.okb : t.erb, borderRadius: BorderRadius.circular(12)),
    child: Text(s, style: TextStyle(fontWeight: FontWeight.w600, color: ok ? t.ok : t.er)),
  );
}

Widget stat(String v, String l) => Expanded(
      child: Builder(builder: (c) {
        final t = tk(c);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: t.sf, border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(l, style: TextStyle(fontSize: 13, color: t.mu))]),
        );
      }),
    );

Widget bar(String l, int v) => Builder(builder: (c) {
      final t = tk(c);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(l)), Text('$v%', style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: v / 100, minHeight: 8, backgroundColor: t.grid, color: t.ac)),
        ]),
      );
    });

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Widget _lbl(String s) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));

Widget field(TextEditingController c, String label, {bool pw = false, bool mono = false, TextInputType? type, int lines = 1, ValueChanged<String>? onChanged, bool enabled = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl(label),
        TextField(controller: c, obscureText: pw, keyboardType: type, maxLines: lines, enabled: enabled, onChanged: onChanged, autocorrect: false, style: mono ? monoStyle() : null),
      ],
    );

Widget dd(String label, String value, List<String> opts, ValueChanged<String> on) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl(label),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: [for (final o in opts) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) {
            if (v != null) on(v);
          },
        ),
      ],
    );

class PlotView extends StatelessWidget {
  final Compiled c;
  final Map<String, double> p;
  final double xr, ratio;
  final bool mini;
  const PlotView({super.key, required this.c, required this.p, this.xr = 6, this.ratio = 1.4, this.mini = false});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.sf, border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(12)),
      child: AspectRatio(aspectRatio: ratio, child: CustomPaint(painter: PlotPainter(c, p, xr, mini, t.grid, t.mu, t.pl))),
    );
  }
}

void _t(Canvas cv, String s, Offset o, Color col) {
  final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: col)), textDirection: TextDirection.ltr)..layout();
  tp.paint(cv, o);
}

class PlotPainter extends CustomPainter {
  final Compiled c;
  final Map<String, double> p;
  final double xr;
  final bool mini;
  final Color grid, axis, curve;
  PlotPainter(this.c, this.p, this.xr, this.mini, this.grid, this.axis, this.curve);

  @override
  void paint(Canvas cv, Size sz) {
    final w = sz.width, h = sz.height;
    double g(double x) => c.f({...p, 'x': x});
    final n = mini ? 90 : 240;
    final xs = <double>[], ys = <double>[];
    var lo = 1e18, hi = -1e18;
    for (var k = 0; k <= n; k++) {
      final x = -xr + 2 * xr * k / n, y = g(x);
      xs.add(x);
      ys.add(y);
      if (y.isFinite && y.abs() < 1e3) {
        lo = min(lo, y);
        hi = max(hi, y);
      }
    }
    if (lo > hi) {
      lo = -5;
      hi = 5;
    }
    final cap = c.used.contains('tan') ? 8.0 : 60.0;
    lo = max(min(lo, -1.0), -cap);
    hi = min(max(hi, 1.0), cap);
    final pd = (hi - lo) * .1;
    lo -= pd;
    hi += pd;
    final sp = hi - lo;
    double sx(double x) => (x + xr) / (2 * xr) * w;
    double sy(double y) => h - (y - lo) / (hi - lo) * h;
    final gp = Paint()..color = grid..strokeWidth = 1;
    final ap = Paint()..color = axis..strokeWidth = 1.4;
    final mg = pow(10, (log(sp / 4) / ln10).floor()).toDouble();
    final st = [1, 2, 5, 10].map((v) => v * mg).firstWhere((v) => sp / v <= 6);
    final xst = xr > 8 ? 2 : 1;
    for (var x = (-xr).ceil(); x <= xr; x += xst) {
      final px = sx(x.toDouble());
      cv.drawLine(Offset(px, 0), Offset(px, h), gp);
      if (!mini && x != 0) _t(cv, '$x', Offset(px + 2, (sy(0) + 3).clamp(0.0, h - 12).toDouble()), axis);
    }
    for (var y = (lo / st).ceil() * st; y <= hi; y += st) {
      cv.drawLine(Offset(0, sy(y)), Offset(w, sy(y)), gp);
      if (!mini && y.abs() > 1e-9) _t(cv, fm(y), Offset(3, sy(y) - 12), axis);
    }
    cv.drawLine(Offset(0, sy(0)), Offset(w, sy(0)), ap);
    cv.drawLine(Offset(sx(0), 0), Offset(sx(0), h), ap);
    final path = Path();
    var pen = false;
    var py = 0.0;
    for (var i = 0; i < xs.length; i++) {
      final y = ys[i];
      if (!y.isFinite || y.abs() > 1e3) {
        pen = false;
        continue;
      }
      final o = Offset(sx(xs[i]), sy(y));
      if (pen && (y - py).abs() < sp * .7) {
        path.lineTo(o.dx, o.dy);
      } else {
        path.moveTo(o.dx, o.dy);
      }
      pen = true;
      py = y;
    }
    cv.save();
    cv.clipRect(Offset.zero & sz);
    cv.drawPath(path, Paint()..color = curve..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeJoin = StrokeJoin.round);
    cv.restore();
  }

  @override
  bool shouldRepaint(covariant PlotPainter o) => true;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  final n = TextEditingController(text: app.user!.nama), nim = TextEditingController(text: app.user!.nim);
  @override
  Widget build(BuildContext context) {
    final u = app.user!, st = u.role == 'mahasiswa', t = tk(context);
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Data profil'),
        field(n, 'Nama'),
        const SizedBox(height: 10),
        field(TextEditingController(text: u.email), 'Email', enabled: false),
        if (st) ...[const SizedBox(height: 10), field(nim, 'NIM', type: TextInputType.number)],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (n.text.trim().length < 3) return snack(context, 'Nama minimal 3 karakter');
              u.nama = n.text.trim();
              u.nim = nim.text.trim();
              app.addL('Profil diperbarui: ${u.email}');
              snack(context, 'Profil tersimpan');
              app.upd();
            },
            child: const Text('Simpan profil'),
          ),
        ),
      ])),
      if (st) card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h3('Progres belajar'), for (final x in topik) bar(x, app.mast[x]!)])),
      if (st) card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h3('Riwayat belajar'), for (final h in app.hist.take(15)) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(h))])),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: t.erb, foregroundColor: t.er),
        onPressed: app.logout,
        child: const Text('Keluar'),
      ),
    ]);
  }
}
