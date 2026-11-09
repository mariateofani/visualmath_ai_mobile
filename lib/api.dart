import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'storage.dart';

/// Klien HTTP ke backend VisualMath AI (Next.js).
class Api {
  static Future<String> get _base async => LocalStore.getBaseUrl();
  static const _timeout = Duration(seconds: 12);

  /// Backend web membaca sesi dari cookie `vma_session` (bukan header Bearer).
  /// Token yang tersimpan dikirim sebagai cookie; header Bearer tetap disertakan
  /// agar kompatibel bila backend kelak menerimanya.
  static Future<Map<String, String>> get _headers async {
    final t = await LocalStore.getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
      if (!kIsWeb) h['Cookie'] = 'vma_session=$t';
    }
    return h;
  }

  /// Mengambil nilai cookie `vma_session` dari header Set-Cookie respons login.
  static String? _sessionFromSetCookie(http.Response r) {
    final raw = r.headers['set-cookie'];
    if (raw == null) return null;
    final m = RegExp(r'vma_session=([^;,\s]+)').firstMatch(raw);
    return m?.group(1);
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final base = await _base;
    final h = await _headers;
    return http.post(Uri.parse('$base$path'), headers: h, body: jsonEncode(body)).timeout(_timeout);
  }

  static Future<http.Response> _get(String path) async {
    final base = await _base;
    final h = await _headers;
    return http.get(Uri.parse('$base$path'), headers: h).timeout(_timeout);
  }

  static dynamic _decode(http.Response r) {
    try { return jsonDecode(r.body); } catch (_) { return null; }
  }

  // ---- Auth ----
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _post('/api/auth/login', {'email': email, 'password': password});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) {
      final user = d['user'];
      final session = d['session'];
      // token bisa dari session.token atau cookie; simpan dari response
      final token = (session is Map ? session['token'] : null) ?? d['token'] ?? _sessionFromSetCookie(r);
      if (token is String) await LocalStore.setToken(token);
      if (user != null) await LocalStore.setUserJson(jsonEncode(user));
      return {'ok': true, 'user': user, 'session': session};
    }
    return {'ok': false, 'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Login gagal'};
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final r = await _post('/api/auth/register', {'name': name, 'email': email, 'password': password, 'role': role});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) {
      final user = d['user'];
      final session = d['session'];
      final token = (session is Map ? session['token'] : null) ?? d['token'] ?? _sessionFromSetCookie(r);
      if (token is String) await LocalStore.setToken(token);
      if (user != null) await LocalStore.setUserJson(jsonEncode(user));
      return {'ok': true, 'user': user};
    }
    return {'ok': false, 'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Registrasi gagal'};
  }

  static Future<void> logout() async {
    try { await _post('/api/auth/logout', {}); } catch (_) {}
    await LocalStore.setToken(null);
    await LocalStore.setUserJson(null);
  }

  static Future<Map<String, dynamic>?> me() async {
    final r = await _get('/api/auth/me');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  // ---- Formulas ----
  static Future<Map<String, dynamic>> analyzeFormula(String expression, {String? topicId}) async {
    final r = await _post('/api/formulas', {'expression': expression, 'topicId': topicId});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return {'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Gagal menganalisis'};
  }

  static Future<List<dynamic>> listFormulas() async {
    final r = await _get('/api/formulas');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['records'] as List?) ?? [];
    return [];
  }

  // ---- Exercises ----
  /// GET /api/exercises. Mengembalikan peta {question, error} atau null bila
  /// gagal. `status` berisi kode HTTP agar pemanggil dapat membedakan 401.
  static Future<Map<String, dynamic>?> getQuestion({String? topicId, String difficulty = 'mudah', String exclude = ''}) async {
    final q = <String, String>{'difficulty': difficulty};
    if (topicId != null) q['topicId'] = topicId;
    if (exclude.isNotEmpty) q['exclude'] = exclude;
    final r = await _get('/api/exercises?${Uri(queryParameters: q).query}');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return {...Map<String, dynamic>.from(d), 'status': r.statusCode};
    return {'question': null, 'status': r.statusCode, 'error': (d is Map ? d['error'] : null) ?? 'HTTP ${r.statusCode}'};
  }

  /// POST /api/exercises/answer. Server memeriksa jawaban, menghitung XP,
  /// mastery, dan tingkat berikutnya.
  static Future<Map<String, dynamic>> answerQuestion({
    required String questionId,
    required String topicId,
    required String sessionId,
    required String answer,
    int? timeMs,
  }) async {
    final r = await _post('/api/exercises/answer', {
      'questionId': questionId,
      'topicId': topicId,
      'sessionId': sessionId,
      'answer': answer,
      if (timeMs != null) 'timeMs': timeMs.clamp(0, 3600000),
    });
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return {...Map<String, dynamic>.from(d), 'status': r.statusCode};
    return {'status': r.statusCode, 'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Gagal mengirim jawaban'};
  }

  /// POST /api/exercises/hint. Mengembalikan teks bantuan atau null.
  static Future<String?> getHint({required String questionId, required String topicId}) async {
    final r = await _post('/api/exercises/hint', {'questionId': questionId, 'topicId': topicId});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map && d['help'] is Map) {
      final t = (d['help'] as Map)['text']?.toString();
      return (t == null || t.isEmpty) ? null : t;
    }
    return null;
  }

  /// POST /api/exercises/complete. Server merekap sesi dan menerbitkan sertifikat.
  static Future<Map<String, dynamic>?> completeSession({required String topicId, required String sessionId, bool quit = false}) async {
    final r = await _post('/api/exercises/complete', {'topicId': topicId, 'sessionId': sessionId, 'finishReason': quit ? 'quit' : 'selesai'});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  // ---- Materials ----
  static Future<List<dynamic>> listMaterials() async {
    final r = await _get('/api/materials');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['materials'] as List?) ?? (d['records'] as List?) ?? [];
    if (d is List) return d;
    return [];
  }

  // ---- Classes ----
  static Future<List<dynamic>> listClasses() async {
    final r = await _get('/api/classes');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['classes'] as List?) ?? (d['records'] as List?) ?? [];
    if (d is List) return d;
    return [];
  }

  // ---- Notifications ----
  static Future<List<dynamic>> listNotifications() async {
    final r = await _get('/api/notifications');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['notifications'] as List?) ?? [];
    if (d is List) return d;
    return [];
  }

  // ---- Profile ----
  static Future<Map<String, dynamic>?> getProfile() async {
    final r = await _get('/api/profile');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  // ---- Scan (OCR) ----
  static Future<Map<String, dynamic>> scan(String base64Image) async {
    final r = await _post('/api/scan', {'image': base64Image});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return {'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Gagal memindai'};
  }

  // ---- Certificates ----
  static Future<List<dynamic>> listCertificates() async {
    // no direct list endpoint; return empty, fetch by id via /api/certificates/[id]
    return [];
  }

  // ---- Topics ----
  static Future<List<dynamic>> listTopics() async {
    final r = await _get('/api/topics');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['topics'] as List?) ?? [];
    if (d is List) return d;
    return [];
  }

  // ---- Users (admin) ----
  static Future<List<dynamic>> listUsers() async {
    final r = await _get('/api/users');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return (d['users'] as List?) ?? [];
    if (d is List) return d;
    return [];
  }

  // ---- AI config ----
  static Future<Map<String, dynamic>?> getAiConfig() async {
    final r = await _get('/api/ai-config');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  // ---- System ----
  static Future<Map<String, dynamic>?> getSystem() async {
    final r = await _get('/api/system');
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }
}