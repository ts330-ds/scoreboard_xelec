import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/athlete_notification_repository.dart';

class AcceptCoachRequestUseCase {
  final AthleteNotificationRepository _repository;

  const AcceptCoachRequestUseCase(this._repository);

  TaskEither<Failure, String> call(int requestId) =>
      _repository.acceptRequest(requestId);
}
