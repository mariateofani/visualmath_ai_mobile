import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage.dart';

/// Klien HTTP ke backend VisualMath AI (Next.js).
class Api {
  static Future<String> get _base async => LocalStore.getBaseUrl();
  static Future<Map<String, String>> get _headers async {
    final t = await LocalStore.getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final base = await _base;
    final h = await _headers;
    return http.post(Uri.parse('$base$path'), headers: h, body: jsonEncode(body));
  }

  static Future<http.Response> _get(String path) async {
    final base = await _base;
    final h = await _headers;
    return http.get(Uri.parse('$base$path'), headers: h);
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
      final token = (session is Map ? session['token'] : null) ?? d['token'];
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
      final token = (session is Map ? session['token'] : null) ?? d['token'];
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
  static Future<Map<String, dynamic>?> getQuestion({String? topicId, String difficulty = 'mudah', String exclude = ''}) async {
    var path = '/api/exercises?difficulty=$difficulty';
    if (topicId != null) path += '&topicId=$topicId';
    if (exclude.isNotEmpty) path += '&exclude=$exclude';
    final r = await _get(path);
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  static Future<Map<String, dynamic>> answerQuestion(String questionId, dynamic answer) async {
    final r = await _post('/api/exercises/answer', {'questionId': questionId, 'answer': answer});
    final d = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && d is Map) return Map<String, dynamic>.from(d);
    return {'error': (d is Map ? d['error'] ?? d['message'] : null) ?? 'Gagal mengirim jawaban'};
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