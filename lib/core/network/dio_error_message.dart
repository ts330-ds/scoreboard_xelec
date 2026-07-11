import 'package:dio/dio.dart';

/// Dio ke raw exception messages (jaise "The request connection took longer
/// than 0:01:00 and it was aborted") user ko dikhane ke liye theek nahi. Ye
/// helper unhe ek saaf, samajhne-yogya message me badalta hai.
///
/// Priority:
///   1. Server ne response body me `message` bheja ho → wahi (sabse specific).
///   2. Error-type based friendly text (timeout / no-connection / etc.).
///   3. [fallback] — badResponse (bina server message) / unknown ke liye
///      caller ka context-specific text (e.g. "Login failed"). Na de to
///      generic "Something went wrong…".
///
/// Network/timeout errors hamesha connectivity-friendly message dete hain
/// (fallback ignore) — kyunki user ka asli issue wahi hota hai.
String friendlyDioMessage(DioException e, {String? fallback}) {
  final serverMsg = _serverBodyMessage(e.response?.data);
  if (serverMsg != null && serverMsg.trim().isNotEmpty) return serverMsg.trim();

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Server is taking too long to respond. '
          'Please check your connection and try again.';
    case DioExceptionType.connectionError:
      return 'Unable to reach the server. '
          'Please check your internet connection.';
    case DioExceptionType.badCertificate:
      return 'Secure connection failed. Please try again.';
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'Session expired. Please log in again.';
      }
      if (code != null && code >= 500) {
        return 'Server error. Please try again later.';
      }
      return fallback ?? 'Something went wrong. Please try again.';
    case DioExceptionType.unknown:
      return fallback ??
          'Something went wrong. Please check your connection and try again.';
  }
}

/// Server response body me se `message` string nikaalo (agar ho).
String? _serverBodyMessage(dynamic data) {
  if (data is Map) {
    final m = data['message'];
    if (m is String) return m;
  }
  return null;
}
