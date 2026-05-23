import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_completed_tasks_usecase.dart';
import 'completed_tasks_state.dart';

class CompletedTasksCubit extends Cubit<CompletedTasksState> {
  final GetCompletedTasksUseCase _getCompletedTasks;

  CompletedTasksCubit(this._getCompletedTasks)
      : super(const CompletedTasksState.initial());

  Future<void> fetch(int athleteId) async {
    emit(state.copyWith(status: CompletedTasksStatus.loading));
    final result = await _getCompletedTasks(athleteId).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CompletedTasksStatus.error,
        errorMessage: failure.message,
      )),
      (tasks) => emit(state.copyWith(
        status: CompletedTasksStatus.loaded,
        tasks: tasks,
      )),
    );
  }
}
