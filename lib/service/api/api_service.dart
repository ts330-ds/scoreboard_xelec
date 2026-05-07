import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio dio;

  final _tokenExpiredController = StreamController<void>.broadcast();
  Stream<void> get tokenExpiredStream => _tokenExpiredController.stream;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            // Login/register endpoints pe 401 expected hai (wrong creds / user not found)
            // Token expire wali handling sirf authenticated requests pe karo
            final isAuthEndpoint = path.contains('/auth/') &&
                (path.contains('/login') || path.contains('/register') || path.contains('/social-login'));
            if (!isAuthEndpoint) {
              clearAuthToken();
              _tokenExpiredController.add(null);
            }
          }
          handler.next(error);
        },
      ),
    );

    // Pretty Logger — sirf debug mode mein
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Auth token set karo (login ke baad call karo)
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Auth token hata do (logout ke baad call karo)
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}
