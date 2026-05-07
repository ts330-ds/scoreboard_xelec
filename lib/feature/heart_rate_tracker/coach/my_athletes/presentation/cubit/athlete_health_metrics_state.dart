import 'package:xelex_esp/feature/heart_rate_tracker/coach/my_athletes/domain/entity/athlete_health_metrics_entity.dart';

enum AthleteHealthMetricsStatus { initial, loading, loaded, error }

class AthleteHealthMetricsState {
  final AthleteHealthMetricsStatus status;
  final AthleteHealthMetricsEntity? metrics;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;

  const AthleteHealthMetricsState({
    required this.status,
    this.metrics,
    this.errorMessage,
    this.fromDate,
    this.toDate,
  });

  AthleteHealthMetricsState copyWith({
    AthleteHealthMetricsStatus? status,
    AthleteHealthMetricsEntity? metrics,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      AthleteHealthMetricsState(
        status: status ?? this.status,
        metrics: metrics ?? this.metrics,
        errorMessage: errorMessage ?? this.errorMessage,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}
