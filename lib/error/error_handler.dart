// error_handler.dart
import 'package:dio/dio.dart';
import 'api_error.dart';

ApiError handleError(Object error, StackTrace stack) {
  if (error is DioException) return _handleDio(error, stack);
  return UnknownError(message: error.toString(), stackTrace: stack);
}

ApiError _handleDio(DioException e, StackTrace stack) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout   ||
    DioExceptionType.connectionError  =>
      NetworkError(message: 'No internet connection', stackTrace: stack),

    DioExceptionType.badResponse =>
      _handleStatus(e.response?.statusCode, stack),

    _ => UnknownError(message: e.message ?? 'Unknown error', stackTrace: stack),
  };
}

ApiError _handleStatus(int? code, StackTrace stack) {
  return switch (code) {
    401 => UnauthorizedError(message: 'Session expired', stackTrace: stack),
    403 => ServerError(message: 'Access denied', statusCode: 403, stackTrace: stack),
    404 => ServerError(message: 'Not found', statusCode: 404, stackTrace: stack),
    500 => ServerError(message: 'Server error', statusCode: 500, stackTrace: stack),
    _   => ServerError(message: 'Something went wrong', statusCode: code ?? 0, stackTrace: stack),
  };
}