import '../../domain/entity/athlete_hour_raw_entity.dart';

enum AthleteHourRawStatus { initial, loading, loaded, error }

class AthleteHourRawState {
  final AthleteHourRawStatus status;
  final AthleteHourRawEntity? data;
  final String? errorMessage;
  final DateTime? date;
  final int? hour;

  const AthleteHourRawState({
    required this.status,
    this.data,
    this.errorMessage,
    this.date,
    this.hour,
  });

  const AthleteHourRawState.initial()
      : status = AthleteHourRawStatus.initial,
        data = null,
        errorMessage = null,
        date = null,
        hour = null;

  AthleteHourRawState copyWith({
    AthleteHourRawStatus? status,
    AthleteHourRawEntity? data,
    String? errorMessage,
    DateTime? date,
    int? hour,
  }) =>
      AthleteHourRawState(
        status: status ?? this.status,
        data: data ?? this.data,
        errorMessage: errorMessage,
        date: date ?? this.date,
        hour: hour ?? this.hour,
      );
}
