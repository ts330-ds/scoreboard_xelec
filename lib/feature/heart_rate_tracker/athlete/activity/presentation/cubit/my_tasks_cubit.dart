import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/get_my_tasks_usecase.dart';
import 'my_tasks_state.dart';

class MyTasksCubit extends Cubit<MyTasksState> {
  final GetMyTasksUseCase _getMyTasks;

  MyTasksCubit({required GetMyTasksUseCase getMyTasks})
      : _getMyTasks = getMyTasks,
        super(const MyTasksState());

  Future<void> fetchTasks() async {
    emit(state.copyWith(status: MyTasksStatus.loading));

    final result = await _getMyTasks().run();

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: MyTasksStatus.error,
        errorMessage: failure.message,
      )),
      (tasks) => emit(state.copyWith(
        status: MyTasksStatus.loaded,
        tasks: tasks,
      )),
    );
  }
}
