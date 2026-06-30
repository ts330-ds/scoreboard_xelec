import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_my_athletes_usecase.dart';
import '../../domain/usecase/remove_athlete_usecase.dart';
import 'my_athletes_state.dart';

class MyAthletesCubit extends Cubit<MyAthletesState> {
  final GetMyAthletesUseCase _getMyAthletes;
  final RemoveAthleteUseCase _removeAthlete;
  Timer? _debounce;
  String? _currentSearch;

  MyAthletesCubit({
    required GetMyAthletesUseCase getMyAthletes,
    required RemoveAthleteUseCase removeAthlete,
  })  : _getMyAthletes = getMyAthletes,
        _removeAthlete = removeAthlete,
        super(const MyAthletesState());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // Initial load — page 1, no search, replaces the list
  Future<void> loadAthletes() async {
    _currentSearch = null;
    emit(state.copyWith(
      status: MyAthletesStatus.loading,
      athletes: [],
      currentPage: 1,
      hasMore: false,
    ));
    await _fetch(page: 1, search: null, append: false);
  }

  // Called on every keystroke — debounced 500ms, resets to page 1
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentSearch = query.trim().isEmpty ? null : query.trim();
      emit(state.copyWith(
        status: MyAthletesStatus.loading,
        athletes: [],
        currentPage: 1,
        hasMore: false,
      ));
      _fetch(page: 1, search: _currentSearch, append: false);
    });
  }

  // Called when user scrolls to the bottom — loads next page and appends.
  // Skips auto-retry while a previous loadMore is in flight or has errored
  // (so a failed page doesn't spam the server on every scroll tick).
  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.status == MyAthletesStatus.loadingMore) return;
    if (state.loadMoreError != null) return;
    await _loadNextPage();
  }

  // Manual retry after a loadMore failure (tapped from the bottom of the list).
  Future<void> retryLoadMore() async {
    if (!state.hasMore) return;
    if (state.status == MyAthletesStatus.loadingMore) return;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final nextPage = state.currentPage + 1;
    emit(state.copyWith(
      status: MyAthletesStatus.loadingMore,
      clearLoadMoreError: true,
    ));
    await _fetch(page: nextPage, search: _currentSearch, append: true);
  }

  // Deletes athlete from server then removes locally — no list reload needed
  Future<bool> removeAthlete(int athleteId) async {
    final result = await _removeAthlete(athleteId).run();
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        final updated = state.athletes.where((a) => a.id != athleteId).toList();
        emit(state.copyWith(
          athletes: updated,
          totalRecords: state.totalRecords - 1,
          status: updated.isEmpty ? MyAthletesStatus.empty : MyAthletesStatus.loaded,
          hasMore: updated.length < (state.totalRecords - 1),
        ));
        return true;
      },
    );
  }

  Future<void> _fetch({
    required int page,
    required String? search,
    required bool append,
  }) async {
    final result =
        await _getMyAthletes(search: search, page: page).run();

    result.fold(
      (failure) => emit(
        append
            // loadMore failure — keep the already-loaded list, surface the
            // error at the bottom so the user can retry without losing data.
            ? state.copyWith(
                status: MyAthletesStatus.loaded,
                loadMoreError: failure.message,
              )
            : state.copyWith(
                status: MyAthletesStatus.error,
                errorMessage: failure.message,
              ),
      ),
      (data) {
        // append=true means loadMore — add new page to existing list
        // append=false means fresh load — replace the list
        final merged = append
            ? [...state.athletes, ...data.athletes]
            : data.athletes;

        // hasMore: if we still haven't loaded all records
        final hasMore = merged.length < data.totalRecords;

        emit(state.copyWith(
          status: merged.isEmpty
              ? MyAthletesStatus.empty
              : MyAthletesStatus.loaded,
          athletes: merged,
          currentPage: page,
          totalRecords: data.totalRecords,
          hasMore: hasMore,
          clearLoadMoreError: true,
        ));
      },
    );
  }
}
