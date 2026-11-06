import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final certs = app.certificates.isNotEmpty ? app.certificates : <Map<String, dynamic>>[];
    if (certs.isEmpty) {
      return page([
        card(Column(children: [
          Icon(Icons.verified_outlined, size: 48, color: tk(context).mu),
          const SizedBox(height: 8),
          muted('Belum ada sertifikat. Selesaikan latihan hingga menguasai topik (skor ≥ 70%) untuk mendapatkan sertifikat.'),
        ])),
      ]);
    }
    return page([
      for (final c in certs) _CertCard(cert: c),
    ]);
  }
}

class _CertCard extends StatefulWidget {
  final Map<String, dynamic> cert;
  const _CertCard({required this.cert});
  @override
  State<_CertCard> createState() => _CertCardState();
}

class _CertCardState extends State<_CertCard> {
  final _sc = ScreenshotController();
  bool _saving = false;

  Future<void> _download() async {
    setState(() => _saving = true);
    try {
      final bytes = await _sc.capture();
      if (bytes == null) throw Exception('Gagal menangkap gambar');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sertifikat_${widget.cert['title']}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Sertifikat VisualMath AI: ${widget.cert['title']}');
      if (mounted) snack(context, 'Sertifikat siap dibagikan/disimpan');
    } catch (e) {
      if (mounted) snack(context, 'Gagal mengunduh: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final c = widget.cert;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(children: [
        Screenshot(
          controller: _sc,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.ac2, t.sf], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.ac, width: 2),
            ),
            child: Column(children: [
              Icon(Icons.verified, color: t.ac, size: 48),
              const SizedBox(height: 8),
              Text('SERTIFIKAT KELULUSAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: t.ac, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text((c['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Diberikan kepada ${app.user?.nama ?? ''}', style: TextStyle(fontSize: 13, color: t.mu)),
              const SizedBox(height: 4),
              Text('Skor: ${(c['score'] ?? '-').toString()}  •  ${(c['issued'] ?? '-').toString()}', style: TextStyle(fontSize: 12, color: t.mu)),
              const SizedBox(height: 4),
              Text('VisualMath AI', style: TextStyle(fontWeight: FontWeight.w700, color: t.ac)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saving ? null : _download,
          icon: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download),
          label: Text(_saving ? 'Menyiapkan...' : 'Unduh / Bagikan Sertifikat'),
        ),
      ]),
    );
  }
}