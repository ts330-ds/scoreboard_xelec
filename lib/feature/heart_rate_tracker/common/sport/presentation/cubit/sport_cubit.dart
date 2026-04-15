import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/usecase/get_sports_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_state.dart';

class SportCubit extends Cubit<SportState> {
  final GetSportsUseCase _getSports;

  SportCubit({required GetSportsUseCase getSports})
      : _getSports = getSports,
        super(const SportState());

  Future<void> getSports() async {
    emit(state.copyWith(status: SportStatus.loading));
    final result = await _getSports().run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SportStatus.error,
        errorMessage: failure.message,
      )),
      (sports) => emit(state.copyWith(
        status: SportStatus.loaded,
        sports: sports,
      )),
    );
  }
}
