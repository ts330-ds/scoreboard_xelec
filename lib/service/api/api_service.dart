import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:xelex_esp/core/logging/file_logger.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio dio;

  final _tokenExpiredController = StreamController<void>.broadcast();
  Stream<void> get tokenExpiredStream => _tokenExpiredController.stream;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['BASE_URL'] ?? '',
        // Reachable server pe connection 1-2s me banta hai — 15s slow mobile
        // network/DNS ke liye kaafi hai. Pehle 60s tha, jisse server down hone
        // par app pura ek minute hang karta tha (+ retry se aur 60s).
        connectTimeout: const Duration(seconds: 15),
        // Dio ki saari calls chhoti JSON hain (bada gzip history push apne
        // HttpClient se jaata hai, Dio se nahi) — 30s safe hai.
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // HttpClient ka connection pool stale ho sakta hai — short idle timeout
    // rakhne se purane broken connections reuse nahi hote.
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 15);
      return client;
    };

    // Interceptors — connection error pe ek baar retry karo (stale pool fix)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          FileLogger.instance.log(
            '→ ${options.method} ${options.uri}'
            '${options.data != null ? '\nbody:\n${prettyJson(options.data)}' : ''}',
            tag: 'API',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          FileLogger.instance.log(
            '← ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.uri}\ndata:\n${prettyJson(response.data)}',
            tag: 'API',
          );
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          FileLogger.instance.log(
            '✖ ${error.type.name} ${error.requestOptions.method} '
            '${error.requestOptions.uri}  '
            'status=${error.response?.statusCode}  '
            'msg=${error.message}\ndata:\n${prettyJson(error.response?.data)}',
            tag: 'API',
            level: 'ERROR',
          );
          // Connection error pe HttpClient reset karke ek retry
          if (_isConnectionError(error) &&
              error.requestOptions.extra['_retried'] != true) {
            debugPrint('[API] Connection error — resetting HttpClient and retrying');
            _resetHttpClient();
            final opts = error.requestOptions;
            opts.extra['_retried'] = true;
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
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

  void _resetHttpClient() {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 15);
      return client;
    };
  }

  static bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout;
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

  /// Raw HttpClient (Dio-bypass) uploads ke 401/403 ke liye. Dio interceptor
  /// un requests ko nahi dekhta, isliye unke auth-failure ko manually yahan
  /// report karo — taaki wahi GLOBAL flow chale jo Dio 401 pe chalta hai
  /// (token clear + tokenExpiredStream → app re-login pe route karta hai).
  /// Sirf pakke 401/403 pe call karo (network/other error pe nahi).
  void notifyTokenExpired() {
    clearAuthToken();
    if (!_tokenExpiredController.isClosed) {
      _tokenExpiredController.add(null);
    }
  }
}
