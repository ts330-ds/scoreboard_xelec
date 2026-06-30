import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/usecase/get_active_tasks_usecase.dart';
import 'coach_live_now_state.dart';

class CoachLiveNowCubit extends Cubit<CoachLiveNowState> {
  final GetActiveTasksUseCase _getActiveTasks;
  String _currentStatus = 'in_progress';

  CoachLiveNowCubit({required GetActiveTasksUseCase getActiveTasks})
      : _getActiveTasks = getActiveTasks,
        super(const CoachLiveNowState());

  // Fresh load — page 1, replaces the list.
  Future<void> loadActiveTasks({String status = 'in_progress'}) async {
    _currentStatus = status;
    emit(state.copyWith(
      status: CoachLiveNowStatus.loading,
      tasks: [],
      currentPage: 1,
      hasMore: false,
      clearLoadMoreError: true,
    ));
    await _fetch(page: 1, append: false);
  }

  // Called when user scrolls to the bottom — loads next page and appends.
  // Skips auto-retry while a previous loadMore is in flight or has errored
  // (so a failed page doesn't spam the server on every scroll tick).
  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.status == CoachLiveNowStatus.loadingMore) return;
    if (state.loadMoreError != null) return;
    await _loadNextPage();
  }

  // Manual retry after a loadMore failure (tapped from the bottom of the list).
  Future<void> retryLoadMore() async {
    if (!state.hasMore) return;
    if (state.status == CoachLiveNowStatus.loadingMore) return;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final nextPage = state.currentPage + 1;
    emit(state.copyWith(
      status: CoachLiveNowStatus.loadingMore,
      clearLoadMoreError: true,
    ));
    await _fetch(page: nextPage, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    final result =
        await _getActiveTasks(status: _currentStatus, page: page).run();

    result.fold(
      (failure) => emit(
        append
            // loadMore failure — keep the already-loaded list, surface the
            // error at the bottom so the user can retry without losing data.
            ? state.copyWith(
                status: CoachLiveNowStatus.loaded,
                loadMoreError: failure.message,
              )
            : state.copyWith(
                status: CoachLiveNowStatus.error,
                errorMessage: failure.message,
              ),
      ),
      (data) {
        // append=true means loadMore — add new page to existing list.
        // append=false means fresh load — replace the list.
        final merged =
            append ? [...state.tasks, ...data.tasks] : data.tasks;

        // hasMore: still haven't loaded all records
        final hasMore = merged.length < data.totalRecords;

        emit(state.copyWith(
          status: CoachLiveNowStatus.loaded,
          tasks: merged,
          currentPage: page,
          totalRecords: data.totalRecords,
          hasMore: hasMore,
          clearLoadMoreError: true,
        ));
      },
    );
  }
}
