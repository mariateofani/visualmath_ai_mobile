import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Lapisan persistensi lokal (token, preferensi, cache offline).
class LocalStore {
  static SharedPreferences? _p;
  static Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  // --- Auth token ---
  static Future<String?> getToken() async => (await _prefs).getString('auth_token');
  static Future<void> setToken(String? v) async {
    final p = await _prefs;
    if (v == null) await p.remove('auth_token'); else await p.setString('auth_token', v);
  }

  // --- User cache (JSON string) ---
  static Future<String?> getUserJson() async => (await _prefs).getString('user_json');
  static Future<void> setUserJson(String? v) async {
    final p = await _prefs;
    if (v == null) await p.remove('user_json'); else await p.setString('user_json', v);
  }

  // --- Base URL ---
  static Future<String> getBaseUrl() async => (await _prefs).getString('base_url') ?? (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000');
  static Future<void> setBaseUrl(String v) async => (await _prefs).setString('base_url', v);

  // --- Theme mode ---
  static Future<String> getThemeMode() async => (await _prefs).getString('theme_mode') ?? 'system';
  static Future<void> setThemeMode(String v) async => (await _prefs).setString('theme_mode', v);

  // --- Generic cache (key -> json string) ---
  static Future<String?> getCache(String key) async => (await _prefs).getString('cache_$key');
  static Future<void> setCache(String key, String? v) async {
    final p = await _prefs;
    if (v == null) await p.remove('cache_$key'); else await p.setString('cache_$key', v);
  }
  static Future<void> clearAll() async => (await _prefs).clear();
}