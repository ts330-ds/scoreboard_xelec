import 'package:equatable/equatable.dart';
import '../../domain/entity/coach_profile_entity.dart';

enum CoachProfileStatus { initial, loading, loaded, updating, updated, error, tokenExpired }

class CoachProfileState extends Equatable {
  final CoachProfileStatus status;
  final CoachProfileEntity? profile;
  final String? errorMessage;

  const CoachProfileState({
    this.status = CoachProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  CoachProfileState copyWith({
    CoachProfileStatus? status,
    CoachProfileEntity? profile,
    String? errorMessage,
  }) =>
      CoachProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
