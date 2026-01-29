enum ErrorType { error, warning, none }

class GlobalErrorState {
  final String message;
  final ErrorType type;

  GlobalErrorState({
    this.message = '',
    this.type = ErrorType.none,
  });

  GlobalErrorState copyWith({
    String? message,
    ErrorType? type,
  }) {
    return GlobalErrorState(
      message: message ?? this.message,
      type: type ?? this.type,
    );
  }
}