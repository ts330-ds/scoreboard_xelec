import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_athlete_hour_raw_usecase.dart';
import 'athlete_hour_raw_state.dart';

class AthleteHourRawCubit extends Cubit<AthleteHourRawState> {
  final GetAthleteHourRawUseCase _getHourRaw;

  AthleteHourRawCubit(this._getHourRaw)
      : super(const AthleteHourRawState.initial());

  Future<void> fetchHour({
    required int athleteId,
    required DateTime date,
    required int hour,
  }) async {
    emit(state.copyWith(
      status: AthleteHourRawStatus.loading,
      date: date,
      hour: hour,
    ));

    final result =
        await _getHourRaw(athleteId: athleteId, date: date, hour: hour).run();

    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteHourRawStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: AthleteHourRawStatus.loaded,
        data: data,
      )),
    );
  }

  void reset() => emit(const AthleteHourRawState.initial());
}
