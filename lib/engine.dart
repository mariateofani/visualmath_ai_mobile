import 'dart:math' as m;

typedef Fn = double Function(Map<String, double>);

class MathErr implements Exception {
  final String msg;
  MathErr(this.msg);
  @override
  String toString() => msg;
}

class Compiled {
  final Fn f;
  final Set<String> used;
  final String src;
  Compiled(this.f, this.used, this.src);
  bool get trig => used.any(const ['sin', 'cos', 'tan'].contains);
}

String fm(double n) {
  if (!n.isFinite) return 'tak hingga';
  var r = (n * 100).round() / 100;
  if (r == 0) r = 0;
  var s = r.toString();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s.replaceAll('.', ',');
}

final _fn = <String, double Function(double)>{
  'sin': (x) => m.sin(x),
  'cos': (x) => m.cos(x),
  'tan': (x) => m.tan(x),
  'sqrt': (x) => m.sqrt(x),
  'abs': (x) => x.abs(),
  'ln': (x) => m.log(x),
  'log': (x) => m.log(x) / m.ln10,
  'exp': (x) => m.exp(x),
};

/// Parser ekspresi (recursive descent). Variabel: x, a, b, c. Fungsi: sin cos tan sqrt abs ln log exp.
Compiled compile(String src) {
  final s = src
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceFirst(RegExp(r'^(y|f\(x\))='), '')
      .replaceAll('π', 'pi')
      .replaceAll('**', '^')
      .replaceAll('×', '*')
      .replaceAll(',', '.');
  if (s.isEmpty) throw MathErr('Rumus masih kosong. Ketik rumus seperti y = 2x + 3.');
  final t = RegExp(r'\d*\.?\d+|[a-z]+|[-+*/^()]').allMatches(s).map((e) => e[0]!).toList();
  if (t.join() != s) {
    throw MathErr('Ada karakter yang tidak dikenali. Gunakan angka, x, a, b, c, + - * / ^ dan fungsi seperti sin(x).');
  }
  var i = 0;
  final used = <String>{};
  String? pk() => i < t.length ? t[i] : null;
  String? nx() => i < t.length ? t[i++] : null;
  bool st(String? k) => k != null && (RegExp(r'^[\d.a-z]').hasMatch(k) || k == '(');
  void need() {
    if (nx() != ')') throw MathErr('Tanda kurung belum ditutup.');
  }

  late Fn Function() tm, un, pw, at;

  Fn ex() {
    Fn l = tm();
    while (pk() == '+' || pk() == '-') {
      final o = nx(), r = tm(), p = l;
      l = o == '+' ? (e) => p(e) + r(e) : (e) => p(e) - r(e);
    }
    return l;
  }

  tm = () {
    Fn l = un();
    for (;;) {
      final k = pk();
      if (k == '*' || k == '/') {
        nx();
        final r = un(), p = l;
        l = k == '*' ? (e) => p(e) * r(e) : (e) => p(e) / r(e);
      } else if (st(k)) {
        final r = pw(), p = l;
        l = (e) => p(e) * r(e);
      } else {
        return l;
      }
    }
  };

  un = () {
    if (pk() == '-') {
      nx();
      final r = un();
      return (e) => -r(e);
    }
    if (pk() == '+') {
      nx();
      return un();
    }
    return pw();
  };

  pw = () {
    final b = at();
    if (pk() == '^') {
      nx();
      final x = un();
      return (e) => m.pow(b(e), x(e)).toDouble();
    }
    return b;
  };

  at = () {
    final k = nx();
    if (k == null) throw MathErr('Rumus belum lengkap: ada operator tanpa angka setelahnya.');
    if (RegExp(r'^[\d.]').hasMatch(k)) {
      final v = double.parse(k);
      return (e) => v;
    }
    if (k == '(') {
      final r = ex();
      need();
      return r;
    }
    if (RegExp(r'^[a-z]').hasMatch(k)) {
      final fn = _fn[k];
      if (fn != null) {
        if (nx() != '(') throw MathErr('Fungsi $k perlu kurung, misalnya $k(x).');
        final r = ex();
        need();
        used.add(k);
        return (e) => fn(r(e));
      }
      if (k == 'pi') return (e) => m.pi;
      if (k == 'e') return (e) => m.e;
      if (k.length == 1 && 'xabc'.contains(k)) {
        used.add(k);
        return (e) => e[k] ?? 0;
      }
      throw MathErr('Simbol tidak dikenal: $k. Variabel yang didukung: x, a, b, c.');
    }
    throw MathErr('Operator $k tidak pada tempatnya.');
  };

  final f = ex();
  if (i < t.length) throw MathErr('Bagian rumus dekat "${t[i]}" tidak bisa dibaca.');
  return Compiled(f, used, s);
}

class An {
  final double Function(double) g;
  final double a, b, c;
  final String type;
  An(this.g, this.a, this.b, this.c, this.type);
}

An analyze(Compiled c, Map<String, double> p) {
  double g(double x) => c.f({...p, 'x': x});
  final C = g(0), A = (g(1) + g(-1)) / 2 - C, B = (g(1) - g(-1)) / 2;
  final poly = !c.trig &&
      [2.0, 3.0, -2.0, .5, 4.0].every((x) => (g(x) - (A * x * x + B * x + C)).abs() < 1e-6 * (1 + g(x).abs()));
  return An(g, A, B, C, c.trig ? 'trig' : poly ? (A.abs() < 1e-9 ? 'lin' : 'quad') : 'gen');
}

List<double> roots(double Function(double) g) {
  final r = <double>[];
  for (var x = -10.0; x < 10; x += .05) {
    var a = x, b = x + .05, ya = g(a);
    final yb = g(b);
    if (!ya.isFinite || !yb.isFinite) continue;
    if (ya == 0) {
      r.add(a);
    } else if (ya * yb < 0) {
      for (var k = 0; k < 40; k++) {
        final mid = (a + b) / 2, ym = g(mid);
        if (ya * ym <= 0) {
          b = mid;
        } else {
          a = mid;
          ya = ym;
        }
      }
      final z = (a + b) / 2;
      if (g(z).abs() < .5) r.add(z);
    }
  }
  final o = <double>[];
  for (final v in r) {
    if (o.isEmpty || (v - o.last).abs() > .1) o.add(v);
  }
  return o;
}

class Ex {
  final List<String> k, l;
  final String h;
  final An a;
  Ex(this.k, this.l, this.h, this.a);
}

/// Penjelasan berbasis aturan (placeholder untuk LLM + RAG di backend).
Ex explain(Compiled c, Map<String, double> p) {
  final a = analyze(c, p), g = a.g, A = a.a, B = a.b, C = a.c;
  final ro = roots(g);
  final rs = ro.isEmpty ? 'tidak ada pada rentang −10 sampai 10' : ro.map(fm).join('; ');
  List<String> k, l;
  String h;
  if (a.type == 'lin') {
    k = [
      'Fungsi linear: grafiknya garis lurus.',
      'Gradien m = ${fm(B)}: setiap x naik 1, nilai y ${B >= 0 ? 'naik' : 'turun'} ${fm(B.abs())}.',
      'Konstanta c = ${fm(C)}: garis memotong sumbu y di (0, ${fm(C)}).'
    ];
    l = [
      'Kenali bentuk y = mx + c, diperoleh m = ${fm(B)} dan c = ${fm(C)}.',
      'Titik potong sumbu y: substitusi x = 0, hasilnya y = ${fm(C)}.',
      B != 0 ? 'Titik potong sumbu x: y = 0, maka x = −c/m = ${fm(-C / B)}.' : 'Karena m = 0, garis datar dan sejajar sumbu x.'
    ];
    h = 'Taksi: biaya = tarif per km × jarak + biaya buka pintu. Gradien adalah tarif per km, konstanta adalah biaya awal.';
  } else if (a.type == 'quad') {
    final d = B * B - 4 * A * C, xv = -B / (2 * A);
    k = [
      'Fungsi kuadrat: grafiknya parabola yang membuka ke ${A > 0 ? 'atas' : 'bawah'} karena a = ${fm(A)}.',
      'Koefisien b = ${fm(B)} menggeser letak puncak; c = ${fm(C)} adalah titik potong sumbu y.',
      'Diskriminan D = b² − 4ac menentukan banyaknya akar.'
    ];
    l = [
      'Kenali a = ${fm(A)}, b = ${fm(B)}, c = ${fm(C)}.',
      'Diskriminan: D = ${fm(d)} (${d > 1e-9 ? 'dua akar berbeda' : d.abs() <= 1e-9 ? 'satu akar kembar' : 'tidak ada akar real'}).',
      'Titik puncak: x = −b/2a = ${fm(xv)}, y = ${fm(g(xv))}.',
      'Akar: $rs.'
    ];
    h = 'Lemparan bola: tinggi h(t) = at² + bt + c. Titik puncak adalah tinggi maksimum bola, akar adalah saat bola mendarat.';
  } else if (a.type == 'trig') {
    var mx = -1e18, mn = 1e18;
    for (var x = -7.0; x <= 7; x += .02) {
      final y = g(x);
      if (y.isFinite && y.abs() < 50) {
        mx = m.max(mx, y);
        mn = m.min(mn, y);
      }
    }
    k = [
      'Fungsi trigonometri: grafiknya berulang secara periodik membentuk gelombang.',
      'Dalam rentang pengamatan, nilai tertinggi ≈ ${fm(mx)} dan terendah ≈ ${fm(mn)}.',
      'Amplitudo ≈ ${fm((mx - mn) / 2)}, garis tengah ≈ ${fm((mx + mn) / 2)}.'
    ];
    l = [
      'Substitusi x = 0: y = ${fm(g(0))}.',
      'Cari nilai maksimum dan minimum dari pola gelombang pada grafik.',
      'Titik potong sumbu x (akar): $rs.'
    ];
    h = 'Gelombang air laut atau ayunan: tinggi air pasang mengikuti pola sinus dengan amplitudo dan periode tertentu.';
  } else {
    k = [
      'Rumus ini bukan linear atau kuadrat sederhana, sehingga dianalisis secara numerik.',
      'Nilai di x = 0: ${fm(g(0))}; nilai di x = 1: ${fm(g(1))}.'
    ];
    l = ['Hitung nilai fungsi pada banyak titik x.', 'Cari perubahan tanda untuk menemukan akar: $rs.'];
    h = 'Pemodelan umum: hubungan antar besaran yang tidak linear, misalnya pertumbuhan atau peluruhan.';
  }
  return Ex(k, l, h, a);
}
