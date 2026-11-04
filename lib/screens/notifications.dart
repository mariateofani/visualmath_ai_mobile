import 'package:flutter/material.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsState();
}

class _NotificationsState extends State<NotificationsScreen> {
  @override
  void initState() { super.initState(); app.refreshRemote(); }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final list = app.notifications;
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Notifikasi'),
        if (list.isEmpty) muted('Belum ada notifikasi.') else ...[
          for (final n in list)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: t.container, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.notifications, color: t.ac, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((n['title'] ?? n['message'] ?? 'Notifikasi').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (n['body'] != null) Text(n['body'].toString(), style: TextStyle(fontSize: 13, color: t.mu)),
                ])),
              ]),
            ),
        ],
      ])),
    ]);
  }
}