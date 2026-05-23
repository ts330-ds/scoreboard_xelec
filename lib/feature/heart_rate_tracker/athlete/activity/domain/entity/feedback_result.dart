class FeedbackResult {
  final int rpe;
  final String note;
  final int sessionDuration; // minutes
  final int trainingLoad;
  final String? submittedAt;
  final String message;

  const FeedbackResult({
    required this.rpe,
    required this.note,
    required this.sessionDuration,
    required this.trainingLoad,
    required this.submittedAt,
    required this.message,
  });
}
