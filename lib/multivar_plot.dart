import 'dart:math';
import 'package:flutter/material.dart';
import 'engine.dart';
import 'theme.dart';

/// Heatmap kontur untuk fungsi dua peubah z = f(x,y).
class MultivarPlot extends StatelessWidget {
  final String expr;
  final double range;
  const MultivarPlot({super.key, required this.expr, this.range = 4});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    Compiled? c;
    try { c = compile(expr.replaceAll('z', 'x').replaceAll('y', 'y')); } catch (_) { c = null; }
    // compile with x,y support: engine uses variable x by default; we evaluate manually via a wrapper
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.sf, border: Border.all(color: t.ln), borderRadius: BorderRadius.circular(12)),
      child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _HeatmapPainter(expr, range, t.grid, t.mu, t.ac))),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final String expr;
  final double range;
  final Color grid, axis, accent;
  _HeatmapPainter(this.expr, this.range, this.grid, this.axis, this.accent);

  double _f(double x, double y) {
    // simple evaluation using a small parser fallback: support x^2 + y^2 style via dart math by replacing
    try {
      // reuse engine compile by treating expression as function of x with y injected as parameter via closure not possible;
      // fallback: evaluate common forms via a tiny evaluator
      return _eval(expr, x, y);
    } catch (_) {
      return 0;
    }
  }

  double _eval(String e, double x, double y) {
    // Very small evaluator supporting + - * / ^ sin cos exp sqrt and variables x,y,pi
    final s = e.toLowerCase().replaceAll(' ', '');
    // Use a recursive descent via a helper
    return _Parser(s, x, y).parse();
  }

  @override
  void paint(Canvas cv, Size sz) {
    final w = sz.width, h = sz.height;
    const n = 60;
    final vals = List.generate(n, (_) => List.filled(n, 0.0));
    double lo = 1e9, hi = -1e9;
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
    final cellW = w / n, cellH = h / n;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final v = vals[i][j];
        final t = ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
        final color = Color.lerp(Colors.blue.shade900, Colors.red.shade600, t)!;
        final rect = Rect.fromLTWH(i * cellW, (n - 1 - j) * cellH, cellW + 0.5, cellH + 0.5);
        cv.drawRect(rect, Paint()..color = color);
      }
    }
    // axes
    final ap = Paint()..color = Colors.white70..strokeWidth = 1.2;
    cv.drawLine(Offset(w / 2, 0), Offset(w / 2, h), ap);
    cv.drawLine(Offset(0, h / 2), Offset(w, h / 2), ap);
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
  double parse() {
    final v = _expr();
    return v;
  }
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
    // functions
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
    // number or variable
    final start = i;
    if (i < s.length && (s[i] == 'x' || s[i] == 'y')) {
      final v = s[i] == 'x' ? x : y;
      i++;
      return v;
    }
    if (s.startsWith('pi', i)) { i += 2; return pi; }
    while (i < s.length && (RegExp(r'[0-9.]').hasMatch(s[i]))) i++;
    if (i > start) return double.tryParse(s.substring(start, i)) ?? 0;
    return 0;
  }
}