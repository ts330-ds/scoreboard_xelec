import 'package:equatable/equatable.dart';
import '../../domain/entity/my_athlete_entity.dart';

enum AthleteDetailStatus { initial, loading, loaded, error }

class AthleteDetailState extends Equatable {
  final AthleteDetailStatus status;
  final MyAthleteEntity? athlete;
  final String? errorMessage;

  const AthleteDetailState({
    this.status = AthleteDetailStatus.initial,
    this.athlete,
    this.errorMessage,
  });

  AthleteDetailState copyWith({
    AthleteDetailStatus? status,
    MyAthleteEntity? athlete,
    String? errorMessage,
  }) =>
      AthleteDetailState(
        status: status ?? this.status,
        athlete: athlete ?? this.athlete,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, athlete, errorMessage];
}
