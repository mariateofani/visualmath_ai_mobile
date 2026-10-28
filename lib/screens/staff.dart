import 'package:flutter/material.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';

int _avg(List<Mb> m) => m.isEmpty ? 0 : (m.fold<int>(0, (s, x) => s + x.v) / m.length).round();

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});
  @override
  Widget build(BuildContext context) {
    final all = app.cls.expand((c) => c.m).toList(), cnt = <String, int>{};
    for (final m in all) {
      cnt[m.l] = (cnt[m.l] ?? 0) + 1;
    }
    final top = cnt.entries.isEmpty ? null : (cnt.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final c = app.cls[app.cs.clamp(0, app.cls.length - 1).toInt()];
    return page([
      Row(children: [stat('${all.length}', 'Mahasiswa'), stat('${_avg(all)}', 'Rata-rata'), stat('${app.cls.length}', 'Kelas')]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Materi tersulit'),
        Text(top == null ? 'Belum ada data.' : '${top.key} menjadi kelemahan ${top.value} mahasiswa. Pertimbangkan menambah materi penguatan.'),
      ])),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < app.cls.length; i++) ChoiceChip(label: Text(app.cls[i].nama, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: app.cs == i ? tk(context).on : tk(context).ink)), selected: app.cs == i, onSelected: (_) {
              app.cs = i;
              app.upd();
            }),
      ]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Nilai ${c.nama} (rata-rata ${_avg(c.m)})'),
        if (c.m.isEmpty) const Text('Belum ada anggota.'),
        for (final m in c.m) bar('${m.n}  ·  lemah: ${m.l}', m.v),
      ])),
    ]);
  }
}

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});
  @override
  State<MaterialScreen> createState() => _MatState();
}

class _MatState extends State<MaterialScreen> {
  final t = TextEditingController();
  String tp = topik.first;
  String? k;
  @override
  Widget build(BuildContext context) {
    k ??= app.cls.first.nama;
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Tambah materi'),
        field(t, 'Judul materi'),
        const SizedBox(height: 10),
        dd('Topik', tp, topik, (v) => setState(() => tp = v)),
        const SizedBox(height: 10),
        dd('Kelas', app.cls.any((c) => c.nama == k) ? k! : app.cls.first.nama, [for (final c in app.cls) c.nama], (v) => setState(() => k = v)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (t.text.trim().length < 3) return snack(context, 'Judul minimal 3 karakter');
              app.mat.insert(0, Mat(DateTime.now().millisecondsSinceEpoch, t.text.trim(), tp, k!));
              app.addL('Materi dibuat: ${t.text.trim()}');
              t.clear();
              snack(context, 'Materi tersimpan');
              app.upd();
            },
            child: const Text('Simpan materi'),
          ),
        ),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Daftar materi (${app.mat.length})'),
        if (app.mat.isEmpty) const Text('Belum ada materi. Tambahkan materi pertama di atas.'),
        for (final m in app.mat)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(m.t, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${m.tp} · ${m.k}'),
            trailing: IconButton(
              tooltip: 'Hapus materi',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.mat.remove(m);
                snack(context, 'Materi dihapus');
                app.upd();
              },
            ),
          ),
      ])),
    ]);
  }
}

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});
  @override
  State<ClassScreen> createState() => _ClsState();
}

class _ClsState extends State<ClassScreen> {
  final kn = TextEditingController();
  final am = <int, TextEditingController>{};
  @override
  Widget build(BuildContext context) {
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Buat kelas'),
        field(kn, 'Nama kelas'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (kn.text.trim().length < 3) return snack(context, 'Nama kelas minimal 3 karakter');
              app.cls.add(Kls(kn.text.trim(), []));
              kn.clear();
              snack(context, 'Kelas dibuat');
              app.upd();
            },
            child: const Text('Buat kelas'),
          ),
        ),
      ])),
      for (var i = 0; i < app.cls.length; i++)
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          h3('${app.cls[i].nama} (${app.cls[i].m.length} anggota)'),
          for (final m in List.of(app.cls[i].m))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.n),
              trailing: TextButton(onPressed: () {
                app.cls[i].m.remove(m);
                app.upd();
              }, child: const Text('Keluarkan')),
            ),
          Row(children: [
            Expanded(child: field(am.putIfAbsent(i, () => TextEditingController()), 'Nama mahasiswa')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () {
              final c = am[i]!;
              if (c.text.trim().length < 3) return snack(context, 'Isi nama mahasiswa');
              app.cls[i].m.add(Mb(c.text.trim(), 0, 'Linear'));
              c.clear();
              app.upd();
            }, child: const Text('Tambah')),
          ]),
        ])),
    ]);
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});
  @override
  Widget build(BuildContext context) {
    int r(String k) => app.users.where((u) => u.role == k).length;
    Widget st(String n) => ListTile(contentPadding: EdgeInsets.zero, title: Text(n), trailing: const Text('Normal', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F8F6F))));
    return page([
      Row(children: [stat('${r('mahasiswa')}', 'Mahasiswa'), stat('${r('dosen')}', 'Dosen'), stat('${app.users.where((u) => u.aktif).length}', 'Aktif')]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Status sistem'),
        st('API backend'),
        st('Layanan AI (${app.ai.model})'),
        st('Mathematical Engine'),
        muted('Data status adalah contoh tampilan; sambungkan ke endpoint /api/v1/health.'),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h3('Aktivitas terbaru'), for (final l in app.logs.take(4)) Text('${l[0]}  ${l[1]}')])),
    ]);
  }
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return page([
      for (final u in List.of(app.users))
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${u.email} · ${u.aktif ? 'aktif' : 'nonaktif'}'),
          Row(children: [
            DropdownButton<String>(
              value: u.role,
              items: [for (final r in ['mahasiswa', 'dosen', 'admin']) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) {
                u.role = v!;
                app.addL('Role ${u.email} menjadi $v');
                snack(context, 'Role diubah');
                app.upd();
              },
            ),
            const Spacer(),
            if (u.id != app.user!.id) ...[
              TextButton(onPressed: () {
                u.aktif = !u.aktif;
                app.addL('${u.aktif ? 'Aktifkan' : 'Nonaktifkan'} ${u.email}');
                app.upd();
              }, child: Text(u.aktif ? 'Nonaktifkan' : 'Aktifkan')),
              TextButton(onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Hapus akun?'),
                    content: Text('Akun ${u.email} akan dihapus permanen.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus'))],
                  ),
                );
                if (ok == true) {
                  app.addL('Hapus akun ${u.email}');
                  app.users.remove(u);
                  app.upd();
                }
              }, child: const Text('Hapus')),
            ],
          ]),
        ])),
    ]);
  }
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _CfgState();
}

class _CfgState extends State<ConfigScreen> {
  late String model = app.ai.model;
  late double temp = app.ai.temp;
  late final lim = TextEditingController(text: '${app.ai.limit}'), pr = TextEditingController(text: app.ai.prompt);
  @override
  Widget build(BuildContext context) {
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Konfigurasi AI'),
        dd('Model', model, const ['LLM Standar', 'LLM Cepat'], (v) => setState(() => model = v)),
        const SizedBox(height: 10),
        Text('Temperature: ${temp.toStringAsFixed(1)}'),
        Slider(value: temp, min: 0, max: 1, divisions: 10, onChanged: (v) => setState(() => temp = v)),
        field(lim, 'Batas permintaan AI per jam', type: TextInputType.number),
        const SizedBox(height: 10),
        field(pr, 'System prompt', lines: 3),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final l = int.tryParse(lim.text) ?? 0;
              if (l < 1 || l > 500) return snack(context, 'Batas harus 1 sampai 500');
              app.ai
                ..model = model
                ..temp = temp
                ..limit = l
                ..prompt = pr.text.trim();
              app.addL('Konfigurasi AI diubah');
              snack(context, 'Konfigurasi tersimpan');
              app.upd();
            },
            child: const Text('Simpan konfigurasi'),
          ),
        ),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [h3('Log aktivitas'), for (final l in app.logs.take(20)) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${l[0]}  ${l[1]}'))])),
    ]);
  }
}
