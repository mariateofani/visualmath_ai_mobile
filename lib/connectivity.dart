import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _c = Connectivity();
  static Future<bool> isOnline() async {
    final r = await _c.checkConnectivity();
    return r != ConnectivityResult.none;
  }
  static Stream<List<ConnectivityResult>> get onChanges => _c.onConnectivityChanged;
}

class OfflineBanner extends StatelessWidget {
  final bool online;
  const OfflineBanner({super.key, required this.online});
  @override
  Widget build(BuildContext context) {
    if (online) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Anda sedang offline. Data dari cache ditampilkan.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}