import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/feedback_result.dart';
import '../../domain/repository/feedback_repository.dart';
import '../datasource/feedback_remote_datasource.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource _remote;

  const FeedbackRepositoryImpl(this._remote);

  @override
  TaskEither<Failure, FeedbackResult> submitFeedback({
    required int taskId,
    required int rpe,
    required String note,
  }) =>
      _remote.submitFeedback(taskId: taskId, rpe: rpe, note: note);
}
