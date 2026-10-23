
import 'package:dio/dio.dart';

class VisualMathApi {
  static const String baseUrl =
      'https://visualmath-ai-phi.vercel.app';

  static final VisualMathApi _instance =
      VisualMathApi._internal();

  factory VisualMathApi() => _instance;

  late final Dio _dio;

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

    return Map<String, dynamic>.from(response.data);
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

    return Map<String, dynamic>.from(response.data);
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

    return Map<String, dynamic>.from(response.data);
  }
}
