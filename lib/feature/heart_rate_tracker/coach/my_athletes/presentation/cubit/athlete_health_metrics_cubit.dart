import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_athlete_health_metrics_usecase.dart';
import 'athlete_health_metrics_state.dart';

class AthleteHealthMetricsCubit extends Cubit<AthleteHealthMetricsState> {
  final GetAthleteHealthMetricsUseCase _getMetrics;

  AthleteHealthMetricsCubit(this._getMetrics)
      : super(const AthleteHealthMetricsState(
          status: AthleteHealthMetricsStatus.initial,
        ));

  Future<void> fetchMetrics(
    int athleteId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    emit(state.copyWith(
      status: AthleteHealthMetricsStatus.loading,
      fromDate: fromDate,
      toDate: toDate,
    ));

    final result = await _getMetrics(
      athleteId: athleteId,
      fromDate: fromDate,
      toDate: toDate,
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteHealthMetricsStatus.error,
        errorMessage: failure.message,
      )),
      (metrics) => emit(state.copyWith(
        status: AthleteHealthMetricsStatus.loaded,
        metrics: metrics,
      )),
    );
  }
}
