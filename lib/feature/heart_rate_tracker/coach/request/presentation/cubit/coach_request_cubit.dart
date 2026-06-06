import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_athletes_usecase.dart';
import '../../domain/usecase/send_athlete_request_usecase.dart';
import 'coach_request_state.dart';

class CoachRequestCubit extends Cubit<CoachRequestState> {
  final GetAthletesUseCase _getAthletes;
  final SendAthleteRequestUseCase _sendAthleteRequest;

  CoachRequestCubit(this._getAthletes, this._sendAthleteRequest)
      : super(const CoachRequestState());

  String _currentQuery = '';

  Future<void> loadAll() => _fetch('', page: 1, append: false);

  Future<void> searchAthletes(String query) {
    _currentQuery = query.trim();
    if (_currentQuery.length < 4) {
      emit(const CoachRequestState());
      return Future.value();
    }
    return _fetch(_currentQuery, page: 1, append: false);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.status == CoachRequestStatus.loadingMore) return;
    final nextPage = state.remainingPages.first;
    return _fetch(_currentQuery, page: nextPage, append: true);
  }

  Future<void> _fetch(String query, {required int page, required bool append}) async {
    if (append) {
      emit(state.copyWith(status: CoachRequestStatus.loadingMore));
    } else {
      emit(state.copyWith(
        status: CoachRequestStatus.loading,
        athletes: [],
        remainingPages: [],
      ));
    }

    final result = await _getAthletes(query, page: page).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachRequestStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        final merged = append ? [...state.athletes, ...data.athletes] : data.athletes;
        emit(merged.isEmpty
            ? state.copyWith(status: CoachRequestStatus.empty, athletes: [], remainingPages: [])
            : state.copyWith(
                status: CoachRequestStatus.loaded,
                athletes: merged,
                remainingPages: data.remainingPages,
              ));
      },
    );
  }

  Future<void> sendRequest(int athleteId) async {
    emit(state.copyWith(status: CoachRequestStatus.sending));
    final result = await _sendAthleteRequest(athleteId).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachRequestStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: CoachRequestStatus.sent)),
    );
  }

  void reset() => emit(const CoachRequestState());
}
