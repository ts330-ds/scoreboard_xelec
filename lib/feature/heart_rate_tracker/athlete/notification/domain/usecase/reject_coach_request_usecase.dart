import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/athlete_notification_repository.dart';

class RejectCoachRequestUseCase {
  final AthleteNotificationRepository _repository;

  const RejectCoachRequestUseCase(this._repository);

  TaskEither<Failure, String> call(int requestId) =>
      _repository.rejectRequest(requestId);
}
