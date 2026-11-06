import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Heatmap kontur untuk fungsi dua peubah z = f(x,y).
class MultivarPlot extends StatelessWidget {
  final String expr;
  final double range;
  const MultivarPlot({super.key, required this.expr, this.range = 4});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: t.sf, border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(12)),
        child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _HeatmapPainter(expr, range, t.grid, t.mu, t.ac))),
      ),
      const SizedBox(height: 6),
      Text('z = $expr   (x,y ∈ [-$range, $range])', style: TextStyle(fontSize: 12, color: t.mu, fontFamily: 'monospace')),
    ]);
  }
}

class _HeatmapPainter extends CustomPainter {
  final String expr;
  final double range;
  final Color grid, axis, accent;
  _HeatmapPainter(this.expr, this.range, this.grid, this.axis, this.accent);

  double _f(double x, double y) {
    try { return _Parser(expr.toLowerCase().replaceAll(' ', ''), x, y).parse(); }
    catch (_) { return 0; }
  }

  @override
  void paint(Canvas cv, Size sz) {
    final w = sz.width, h = sz.height;
    const n = 80;
    final vals = List.generate(n, (_) => List.filled(n, 0.0));
    double lo = double.infinity, hi = -double.infinity;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final x = -range + 2 * range * i / (n - 1);
        final y = -range + 2 * range * j / (n - 1);
        final v = _f(x, y);
        vals[i][j] = v;
        if (v.isFinite) { lo = min(lo, v); hi = max(hi, v); }
      }
    }
    if (!lo.isFinite || !hi.isFinite || lo == hi) { lo = -1; hi = 1; }

    // heatmap
    final cellW = w / n, cellH = h / n;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final v = vals[i][j];
        final t = ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
        final color = _colormap(t);
        final rect = Rect.fromLTWH(i * cellW, (n - 1 - j) * cellH, cellW + 0.5, cellH + 0.5);
        cv.drawRect(rect, Paint()..color = color);
      }
    }

    // contour lines (iso-values)
    final levels = 8;
    for (var k = 1; k < levels; k++) {
      final level = lo + (hi - lo) * k / levels;
      final cp = Paint()..color = Colors.white.withAlpha(90)..strokeWidth = 1..style = PaintingStyle.stroke;
      // marching squares simplified: draw segments where cell crosses level
      for (var i = 0; i < n - 1; i++) {
        for (var j = 0; j < n - 1; j++) {
          final a = vals[i][j], b = vals[i + 1][j], c = vals[i][j + 1], d = vals[i + 1][j + 1];
          // bilinear interp points on edges
          final pts = <Offset>[];
          // bottom edge a-b
          if ((a - level) * (b - level) < 0) pts.add(Offset((i + (level - a) / (b - a)) * cellW, (n - 1 - j) * cellH));
          // top edge c-d
          if ((c - level) * (d - level) < 0) pts.add(Offset((i + (level - c) / (d - c)) * cellW, (n - 2 - j) * cellH));
          // left edge a-c
          if ((a - level) * (c - level) < 0) pts.add(Offset(i * cellW, (n - 1 - j - (level - a) / (c - a)) * cellH));
          // right edge b-d
          if ((b - level) * (d - level) < 0) pts.add(Offset((i + 1) * cellW, (n - 1 - j - (level - b) / (d - b)) * cellH));
          if (pts.length >= 2) {
            cv.drawLine(pts[0], pts[1], cp);
          }
        }
      }
    }

    // axes
    final ap = Paint()..color = Colors.white..strokeWidth = 1.5;
    cv.drawLine(Offset(w / 2, 0), Offset(w / 2, h), ap);
    cv.drawLine(Offset(0, h / 2), Offset(w, h / 2), ap);
    // tick labels
    for (var i = 0; i <= 4; i++) {
      final v = -range + 2 * range * i / 4;
      final x = i * w / 4;
      _txt(cv, v.toStringAsFixed(0), Offset(x - 6, h / 2 + 4), Colors.white);
      final y = i * h / 4;
      _txt(cv, (range - 2 * range * i / 4).toStringAsFixed(0), Offset(w / 2 + 4, y - 6), Colors.white);
    }
  }

  Color _colormap(double t) {
    // blue -> cyan -> green -> yellow -> red
    if (t < 0.25) return Color.lerp(const Color(0xFF1a237e), const Color(0xFF00bcd4), t / 0.25)!;
    if (t < 0.5) return Color.lerp(const Color(0xFF00bcd4), const Color(0xFF4caf50), (t - 0.25) / 0.25)!;
    if (t < 0.75) return Color.lerp(const Color(0xFF4caf50), const Color(0xFFffeb3b), (t - 0.5) / 0.25)!;
    return Color.lerp(const Color(0xFFffeb3b), const Color(0xFFd32f2f), (t - 0.75) / 0.25)!;
  }

  void _txt(Canvas cv, String s, Offset o, Color c) {
    final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, o);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) => old.expr != expr || old.range != range;
}

// ---- tiny expression evaluator ----
class _Parser {
  final String s;
  final double x, y;
  int i = 0;
  _Parser(this.s, this.x, this.y);
  double parse() => _expr();
  double _expr() {
    double v = _term();
    while (i < s.length && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++];
      final t = _term();
      v = op == '+' ? v + t : v - t;
    }
    return v;
  }
  double _term() {
    double v = _pow();
    while (i < s.length && (s[i] == '*' || s[i] == '/')) {
      final op = s[i++];
      final p = _pow();
      v = op == '*' ? v * p : v / p;
    }
    return v;
  }
  double _pow() {
    double v = _unary();
    if (i < s.length && s[i] == '^') {
      i++;
      final r = _pow();
      v = pow(v, r).toDouble();
    }
    return v;
  }
  double _unary() {
    if (i < s.length && s[i] == '-') { i++; return -_primary(); }
    if (i < s.length && s[i] == '+') { i++; return _primary(); }
    return _primary();
  }
  double _primary() {
    if (i < s.length && s[i] == '(') {
      i++;
      final v = _expr();
      if (i < s.length && s[i] == ')') i++;
      return v;
    }
    for (final f in ['sin', 'cos', 'tan', 'exp', 'sqrt', 'abs', 'log']) {
      if (s.startsWith(f, i)) {
        i += f.length;
        if (i < s.length && s[i] == '(') i++;
        final v = _expr();
        if (i < s.length && s[i] == ')') i++;
        switch (f) {
          case 'sin': return sin(v);
          case 'cos': return cos(v);
          case 'tan': return tan(v);
          case 'exp': return exp(v);
          case 'sqrt': return sqrt(v.abs());
          case 'abs': return v.abs();
          case 'log': return log(v.abs() + 1e-9);
        }
      }
    }
    final start = i;
    if (i < s.length && (s[i] == 'x' || s[i] == 'y')) {
      final v = s[i] == 'x' ? x : y;
      i++;
      return v;
    }
    if (s.startsWith('pi', i)) { i += 2; return pi; }
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) i++;
    if (i > start) return double.tryParse(s.substring(start, i)) ?? 0;
    return 0;
  }
}