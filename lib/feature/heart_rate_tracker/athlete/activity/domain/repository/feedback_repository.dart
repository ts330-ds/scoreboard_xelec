import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/feedback_result.dart';

abstract interface class FeedbackRepository {
  TaskEither<Failure, FeedbackResult> submitFeedback({
    required int taskId,
    required int rpe,
    required String note,
  });
}
