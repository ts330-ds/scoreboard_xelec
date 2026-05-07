import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_athlete_detail_usecase.dart';
import 'athlete_detail_state.dart';

class AthleteDetailCubit extends Cubit<AthleteDetailState> {
  final GetAthleteDetailUseCase _getAthleteDetail;

  AthleteDetailCubit({required GetAthleteDetailUseCase getAthleteDetail})
      : _getAthleteDetail = getAthleteDetail,
        super(const AthleteDetailState());

  Future<void> fetchDetail(int athleteId) async {
    emit(state.copyWith(status: AthleteDetailStatus.loading));
    final result = await _getAthleteDetail(athleteId).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteDetailStatus.error,
        errorMessage: failure.message,
      )),
      (athlete) => emit(state.copyWith(
        status: AthleteDetailStatus.loaded,
        athlete: athlete,
      )),
    );
  }
}
