import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/sport.dart';
import '../repository/sport_repository.dart';

class GetSportsUseCase {
  final SportRepository _repository;

  const GetSportsUseCase(this._repository);

  TaskEither<Failure, List<Sport>> call() => _repository.getSports();
}
