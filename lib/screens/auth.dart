import 'package:flutter/material.dart';
import '../common.dart';
import '../engine.dart';
import '../state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  bool masuk = true;
  String role = 'mahasiswa';
  String? err;
  final n = TextEditingController(), e = TextEditingController(), p = TextEditingController();

  void submit() {
    final r = masuk ? app.login(e.text, p.text) : app.register(n.text, e.text, p.text, role);
    if (r != null) setState(() => err = r);
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final c = compile('2*sin(x)+0.5*x');
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
          PlotView(c: c, p: const {}, xr: 7, ratio: 2.27, mini: true),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Visual'),
              TextSpan(text: 'Math', style: TextStyle(color: t.ac)),
              const TextSpan(text: ' AI'),
            ]),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.5),
          ),
          muted('Pahami rumus, bukan hanya jawabannya.'),
          const SizedBox(height: 14),
          _Seg(masuk: masuk, on: (v) => setState(() {
                masuk = v;
                err = null;
              })),
          const SizedBox(height: 14),
          if (err != null) ...[msg(context, err!), const SizedBox(height: 14)],
          if (!masuk) ...[
            field(n, 'Nama lengkap'),
            const SizedBox(height: 10),
            dd('Peran', role, const ['mahasiswa', 'dosen'], (v) => setState(() => role = v)),
            const SizedBox(height: 10),
          ],
          field(e, 'Email', type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          field(p, 'Kata sandi', pw: true),
          const SizedBox(height: 14),
          FilledButton(onPressed: submit, child: Text(masuk ? 'Masuk' : 'Buat akun')),
          if (masuk) ...[
            const SizedBox(height: 14),
            muted('Akun contoh (kata sandi 1234):'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final r in ['mhs', 'dosen', 'admin'])
                ActionChip(
                  label: Text('$r@vma.id'),
                  onPressed: () => setState(() {
                    e.text = '$r@vma.id';
                    p.text = '1234';
                  }),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final bool masuk;
  final ValueChanged<bool> on;
  const _Seg({required this.masuk, required this.on});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.ac2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (final e in [(true, 'Masuk'), (false, 'Daftar')])
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => on(e.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: masuk == e.$1 ? t.ac : null, borderRadius: BorderRadius.circular(9)),
                child: Text(e.$2, style: TextStyle(fontWeight: FontWeight.w700, color: masuk == e.$1 ? t.on : t.ac)),
              ),
            ),
          ),
      ]),
    );
  }
}
