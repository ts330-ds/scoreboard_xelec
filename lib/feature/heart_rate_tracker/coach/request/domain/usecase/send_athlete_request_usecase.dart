import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/coach_request_repository.dart';

class SendAthleteRequestUseCase {
  final CoachRequestRepository _repository;
  const SendAthleteRequestUseCase(this._repository);

  TaskEither<Failure, void> call(int athleteId) =>
      _repository.sendAthleteRequest(athleteId);
}
