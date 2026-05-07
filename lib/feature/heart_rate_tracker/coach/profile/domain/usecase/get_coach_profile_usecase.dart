import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_profile_entity.dart';
import '../repository/coach_profile_repository.dart';

class GetCoachProfileUseCase {
  final CoachProfileRepository _repository;

  const GetCoachProfileUseCase(this._repository);

  TaskEither<Failure, CoachProfileEntity> call() => _repository.getProfile();
}
