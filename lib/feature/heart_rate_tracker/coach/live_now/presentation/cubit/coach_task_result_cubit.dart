import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_coach_task_result_usecase.dart';
import 'coach_task_result_state.dart';

class CoachTaskResultCubit extends Cubit<CoachTaskResultState> {
  final GetCoachTaskResultUseCase _getTaskResult;
  final int taskId;

  CoachTaskResultCubit({
    required this.taskId,
    required GetCoachTaskResultUseCase getTaskResult,
  })  : _getTaskResult = getTaskResult,
        super(const CoachTaskResultState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: CoachTaskResultStatus.loading));
    final result = await _getTaskResult(taskId).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachTaskResultStatus.error,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: CoachTaskResultStatus.loaded,
        result: data,
      )),
    );
  }
}
