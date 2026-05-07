import 'package:equatable/equatable.dart';
import '../../domain/entity/coach_auth_entity.dart';

enum CoachAuthStatus { initial, loading, authenticated, notRegistered, loggingOut, loggedOut, error }

class CoachAuthState extends Equatable {
  final CoachAuthStatus status;
  final CoachAuthEntity? coach;
  final String? errorMessage;

  const CoachAuthState({
    this.status = CoachAuthStatus.initial,
    this.coach,
    this.errorMessage,
  });

  CoachAuthState copyWith({
    CoachAuthStatus? status,
    CoachAuthEntity? coach,
    String? errorMessage,
  }) => CoachAuthState(
    status: status ?? this.status,
    coach: coach ?? this.coach,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, coach, errorMessage];
}
