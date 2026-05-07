import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/my_athletes_remote_datasource.dart';
import '../repository/my_athletes_repository.dart';

class GetMyAthletesUseCase {
  final MyAthletesRepository _repository;
  const GetMyAthletesUseCase(this._repository);

  TaskEither<Failure, MyAthletesResult> call({
    String? search,
    int page = 1,
  }) =>
      _repository.getMyAthletes(search: search, page: page);
}
