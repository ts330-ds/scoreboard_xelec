import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/entity/sport.dart';
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
    // API return hone se pehle user sheet band / tab change kar sakta hai —
    // cubit close ho chuka hota hai, aur emit "Bad state: cannot emit after
    // close" throw karta hai. Isliye await ke baad guard.
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: SportStatus.error,
        errorMessage: failure.message,
      )),
      (sports) {
        final list = sports.isNotEmpty
            ? sports
            : const [
                Sport(id: 1, name: 'Football'),
                Sport(id: 2, name: 'Basketball'),
                Sport(id: 3, name: 'Cricket'),
                Sport(id: 4, name: 'Tennis'),
                Sport(id: 5, name: 'Swimming'),
              ];
        final sorted = List<Sport>.from(list)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        emit(state.copyWith(status: SportStatus.loaded, sports: sorted));
      },
    );
  }
}
