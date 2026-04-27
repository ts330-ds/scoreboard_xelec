import 'package:equatable/equatable.dart';
import '../../domain/entity/athlete_auth_entity.dart';

enum AthleteAuthStatus { initial, loading, authenticated, notRegistered, loggingOut, loggedOut, error }

class AthleteAuthState extends Equatable {
  final AthleteAuthStatus status;
  final AthleteAuthEntity? athlete;
  final String? errorMessage;

  const AthleteAuthState({
    this.status = AthleteAuthStatus.initial,
    this.athlete,
    this.errorMessage,
  });

  AthleteAuthState copyWith({
    AthleteAuthStatus? status,
    AthleteAuthEntity? athlete,
    String? errorMessage,
  }) => AthleteAuthState(
    status: status ?? this.status,
    athlete: athlete ?? this.athlete,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, athlete, errorMessage];
}
