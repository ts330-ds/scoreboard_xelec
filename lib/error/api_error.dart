// api_error.dart — wohi sealed class
sealed class ApiError {
  final String message;
  final StackTrace? stackTrace;
  const ApiError({required this.message, this.stackTrace});
}

final class NetworkError extends ApiError {
  const NetworkError({required super.message, super.stackTrace});
}

final class ServerError extends ApiError {
  final int statusCode;
  const ServerError({
    required super.message,
    required this.statusCode,
    super.stackTrace,
  });
}

final class UnauthorizedError extends ApiError {
  const UnauthorizedError({required super.message, super.stackTrace});
}

final class UnknownError extends ApiError {
  const UnknownError({required super.message, super.stackTrace});
}