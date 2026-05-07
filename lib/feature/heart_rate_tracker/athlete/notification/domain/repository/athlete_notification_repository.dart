import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_request_entity.dart';

abstract interface class AthleteNotificationRepository {
  TaskEither<Failure, List<CoachRequestEntity>> getCoachRequests();
  TaskEither<Failure, String> acceptRequest(int requestId);
  TaskEither<Failure, String> rejectRequest(int requestId);
}
