import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/feedback_result.dart';
import '../repository/feedback_repository.dart';

class SubmitFeedbackUseCase {
  final FeedbackRepository _repo;

  const SubmitFeedbackUseCase(this._repo);

  TaskEither<Failure, FeedbackResult> call({
    required int taskId,
    required int rpe,
    required String note,
  }) =>
      _repo.submitFeedback(taskId: taskId, rpe: rpe, note: note);
}
