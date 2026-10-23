
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class VisualMathApi {
  static const String baseUrl =
      'https://visualmath-ai-phi.vercel.app';

  static final VisualMathApi _instance =
      VisualMathApi._internal();

  factory VisualMathApi() => _instance;

  late final Dio _dio;
  late final CookieJar _cookieJar;

  VisualMathApi._internal() {
    _cookieJar = CookieJar();

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

    _dio.interceptors.add(
      CookieManager(_cookieJar),
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

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
