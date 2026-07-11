import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/get_my_tasks_usecase.dart';
import 'my_tasks_state.dart';

class MyTasksCubit extends Cubit<MyTasksState> {
  final GetMyTasksUseCase _getMyTasks;

  MyTasksCubit({required GetMyTasksUseCase getMyTasks})
      : _getMyTasks = getMyTasks,
        super(const MyTasksState());

  // Initial load / pull-to-refresh — page 1, replaces the list.
  //
  // Do-phase (backend ki wajah se zaroori): `?page=1` list me `in_progress`
  // task aata HI NAHI — use detect karne ke liye alag `?status=in_progress`
  // call chahiye. Isliye pehle wahi check karo:
  //   • in_progress mila → athlete ko usi pe force karo (banner), list load hi
  //     mat karo — sirf 1 call.
  //   • koi in_progress nahi → normal list laao (2nd call).
  Future<void> fetchTasks() async {
    if (state.status == MyTasksStatus.loading) return;

    emit(state.copyWith(
      status: MyTasksStatus.loading,
      clearError: true,
      clearInProgress: true,
    ));

    final blocking = await _findInProgressTask();
    if (isClosed) return;
    if (blocking != null) {
      emit(state.copyWith(
        status: MyTasksStatus.loaded,
        inProgressTask: blocking,
      ));
      return;
    }

    await _fetch(page: 1, append: false);
  }

  // Server-authoritative in_progress check — `?status=in_progress` zaroori hai
  // (default list ise exclude karta hai). Network error pe null (offline athlete
  // ko list se lock out mat karo). Client-side dobara filter — defensive.
  Future<AthleteTaskEntity?> _findInProgressTask() async {
    final result = await _getMyTasks(page: 1, status: 'in_progress').run();
    return result.fold(
      (_) => null,
      (data) => _findInProgress(data.tasks),
    );
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

  AthleteTaskEntity? _findInProgress(List<AthleteTaskEntity> tasks) {
    for (final t in tasks) {
      final s = t.status?.toLowerCase();
      if (s == 'in_progress' || s == 'active') return t;
    }
    return null;
  }
}
