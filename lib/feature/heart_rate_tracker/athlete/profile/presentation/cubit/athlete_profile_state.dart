import 'package:equatable/equatable.dart';
import '../../domain/entity/athlete_profile_entity.dart';

enum AthleteProfileStatus { initial, loading, loaded, updating, updated, error }

class AthleteProfileState extends Equatable {
  final AthleteProfileStatus status;
  final AthleteProfileEntity? profile;
  final String? errorMessage;

  const AthleteProfileState({
    this.status = AthleteProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  AthleteProfileState copyWith({
    AthleteProfileStatus? status,
    AthleteProfileEntity? profile,
    String? errorMessage,
  }) =>
      AthleteProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
