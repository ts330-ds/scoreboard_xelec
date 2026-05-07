import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/usecase/get_active_tasks_usecase.dart';
import 'coach_live_now_state.dart';

class CoachLiveNowCubit extends Cubit<CoachLiveNowState> {
  final GetActiveTasksUseCase _getActiveTasks;

  CoachLiveNowCubit({required GetActiveTasksUseCase getActiveTasks})
      : _getActiveTasks = getActiveTasks,
        super(const CoachLiveNowState());

  Future<void> loadActiveTasks({String status = 'in_progress'}) async {
    emit(state.copyWith(status: CoachLiveNowStatus.loading));

    final result = await _getActiveTasks(status: status).run();

    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachLiveNowStatus.error,
        errorMessage: failure.message,
      )),
      (tasks) => emit(state.copyWith(
        status: CoachLiveNowStatus.loaded,
        tasks: tasks,
      )),
    );
  }
}
