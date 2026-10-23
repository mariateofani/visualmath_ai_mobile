
import 'package:dio/dio.dart';

class VisualMathApi {
  static const String baseUrl =
      'https://visualmath-ai-phi.vercel.app';

  static final VisualMathApi _instance =
      VisualMathApi._internal();

  factory VisualMathApi() => _instance;

  late final Dio _dio;

  // Cookie sesi dari server.
  String? _sessionCookie;

  VisualMathApi._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Kirim cookie pada permintaan yang memerlukan sesi.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_sessionCookie != null &&
              _sessionCookie!.isNotEmpty) {
            options.headers['Cookie'] = _sessionCookie;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _saveSessionCookie(response);
          handler.next(response);
        },
      ),
    );
  }

  void _saveSessionCookie(Response response) {
    final cookies = response.headers['set-cookie'];

    if (cookies == null || cookies.isEmpty) return;

    for (final cookie in cookies) {
      // Simpan pasangan nama=nilai saja, bukan atribut
      // seperti Path, HttpOnly, Secure, atau SameSite.
      final pair = cookie.split(';').first.trim();

      if (pair.startsWith('vma_session=')) {
        if (pair == 'vma_session=') {
          _sessionCookie = null;
        } else {
          _sessionCookie = pair;
        }
        return;
      }
    }
  }

  // LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    return _asMap(response.data);
  }

  // REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
    String? nim,
    String? prodi,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
        if (nim != null && nim.trim().isNotEmpty)
          'nim': nim.trim(),
        if (prodi != null && prodi.trim().isNotEmpty)
          'prodi': prodi.trim(),
      },
    );

    return _asMap(response.data);
  }

  // ANALISIS RUMUS
  Future<Map<String, dynamic>> analyzeFormula(
    String expression,
  ) async {
    final response = await _dio.post(
      '/api/formulas',
      data: {
        'expression': expression,
        'variable': 'x',
      },
    );

    return _asMap(response.data);
  }

  // LOGOUT LOKAL
  void clearSession() {
    _sessionCookie = null;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException(
      'Respons server bukan objek JSON.',
    );
  }
}
