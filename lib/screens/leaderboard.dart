import 'package:flutter/material.dart';
import '../common.dart';
import '../state.dart';
import '../theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final data = app.leaderboard.isNotEmpty
        ? app.leaderboard
        : [
            {'name': 'Dina Pratama', 'xp': 320, 'rank': 1},
            {'name': 'Citra Lestari', 'xp': 290, 'rank': 2},
            {'name': 'Eka Wulandari', 'xp': 250, 'rank': 3},
            {'name': app.user?.nama ?? 'Anda', 'xp': app.xp, 'rank': 4},
          ];
    return page([
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        h3('Peringkat'),
        for (final d in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: (d['rank'] == 1) ? Colors.amber : t.ac2, child: Text('${d['rank']}', style: TextStyle(fontWeight: FontWeight.w800, color: (d['rank'] == 1) ? Colors.white : t.ac))),
              const SizedBox(width: 12),
              Expanded(child: Text((d['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${d['xp']} XP', style: TextStyle(fontWeight: FontWeight.w800, color: t.ac)),
            ]),
          ),
      ])),
    ]);
  }
}