import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_request_entity.dart';
import '../repository/athlete_notification_repository.dart';

class GetCoachRequestsUseCase {
  final AthleteNotificationRepository _repository;

  const GetCoachRequestsUseCase(this._repository);

  TaskEither<Failure, List<CoachRequestEntity>> call() =>
      _repository.getCoachRequests();
}
