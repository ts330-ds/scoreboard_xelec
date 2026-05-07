import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_task_result_usecase.dart';
import 'task_result_state.dart';

class TaskResultCubit extends Cubit<TaskResultState> {
  final GetTaskResultUseCase _getTaskResult;
  final int taskId;

  TaskResultCubit({
    required this.taskId,
    required GetTaskResultUseCase getTaskResult,
  })  : _getTaskResult = getTaskResult,
        super(const TaskResultState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: TaskResultStatus.loading));
    final result = await _getTaskResult(taskId).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskResultStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: TaskResultStatus.loaded,
        result: data,
      )),
    );
  }
}
