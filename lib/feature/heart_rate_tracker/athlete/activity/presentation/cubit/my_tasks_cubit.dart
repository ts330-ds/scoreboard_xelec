import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/get_my_tasks_usecase.dart';
import 'my_tasks_state.dart';

class MyTasksCubit extends Cubit<MyTasksState> {
  final GetMyTasksUseCase _getMyTasks;

  MyTasksCubit({required GetMyTasksUseCase getMyTasks})
      : _getMyTasks = getMyTasks,
        super(const MyTasksState());

  // Initial load / pull-to-refresh — page 1, replaces the list.
  Future<void> fetchTasks() async {
    if (state.status == MyTasksStatus.loading) return;

    emit(state.copyWith(status: MyTasksStatus.loading, clearError: true));
    await _fetch(page: 1, append: false);
  }

  // Called when the user scrolls to the bottom — loads next page and appends.
  Future<void> loadMore() async {
    if (!state.hasMore) return;
    if (state.status == MyTasksStatus.loading ||
        state.status == MyTasksStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: MyTasksStatus.loadingMore));
    await _fetch(page: state.currentPage + 1, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    final result = await _getMyTasks(page: page).run();

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: MyTasksStatus.error,
        errorMessage: failure.message,
        isAuthError: failure is AuthFailure,
      )),
      (data) {
        final merged =
            append ? [...state.tasks, ...data.tasks] : data.tasks;
        emit(state.copyWith(
          status: MyTasksStatus.loaded,
          tasks: merged,
          currentPage: page,
          totalRecords: data.totalRecords,
          hasMore: merged.length < data.totalRecords,
        ));
      },
    );
  }
}
