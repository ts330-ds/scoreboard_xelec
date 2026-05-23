import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/submit_feedback_usecase.dart';

import 'session_feedback_state.dart';

class SessionFeedbackCubit extends Cubit<SessionFeedbackState> {
  final SubmitFeedbackUseCase _submitFeedback;
  final int _taskId;

  SessionFeedbackCubit({
    required SubmitFeedbackUseCase submitFeedback,
    required int taskId,
  })  : _submitFeedback = submitFeedback,
        _taskId = taskId,
        super(const SessionFeedbackState());

  void setDifficulty(int value) {
    final clamped = value.clamp(0, 10);
    emit(state.copyWith(difficulty: clamped));
  }

  void setNotes(String value) => emit(state.copyWith(notes: value));

  Future<void> submit() async {
    if (state.isSubmitting || state.isSubmitted) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _submitFeedback(
      taskId: _taskId,
      rpe: state.difficulty,
      note: state.notes.trim(),
    ).run();

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        isSubmitting: false,
        isSubmitted: true,
        result: data,
      )),
    );
  }
}
