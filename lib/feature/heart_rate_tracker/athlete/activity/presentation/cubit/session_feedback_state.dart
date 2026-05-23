import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/feedback_result.dart';

class SessionFeedbackState {
  final int difficulty; // 0 (Extremely easy) → 10 (Maximal) — payload rpe
  final String notes;
  final bool isSubmitting;
  final bool isSubmitted;
  final FeedbackResult? result;
  final String? errorMessage;

  const SessionFeedbackState({
    this.difficulty = 0,
    this.notes = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.result,
    this.errorMessage,
  });

  SessionFeedbackState copyWith({
    int? difficulty,
    String? notes,
    bool? isSubmitting,
    bool? isSubmitted,
    FeedbackResult? result,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SessionFeedbackState(
        difficulty: difficulty ?? this.difficulty,
        notes: notes ?? this.notes,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        result: result ?? this.result,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}
