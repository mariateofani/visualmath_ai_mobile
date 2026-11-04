import 'package:flutter/material.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    // sertifikat dari data lokal (mock) + remote jika ada
    final certs = app.certificates.isNotEmpty
        ? app.certificates
        : [
            {'title': 'Kalkulus Dasar', 'issued': '2026-10-12', 'score': 88},
          ];
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Sertifikat saya'),
        if (certs.isEmpty) muted('Belum ada sertifikat. Selesaikan latihan untuk mendapatkan sertifikat.')
        else ...[
          for (final c in certs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.ac2, t.sf], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.ln),
              ),
              child: Row(children: [
                Icon(Icons.verified, color: t.ac, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((c['title'] ?? 'Sertifikat').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('Diterbitkan: ${(c['issued'] ?? '-').toString()}', style: TextStyle(fontSize: 12, color: t.mu)),
                  Text('Skor: ${(c['score'] ?? '-').toString()}', style: TextStyle(fontSize: 12, color: t.mu)),
                ])),
              ]),
            ),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () => app.go('home'), icon: const Icon(Icons.school), label: const Text('Lanjut belajar')),
      ])),
    ]);
  }
}