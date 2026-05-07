import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/coach_request_remote_datasource.dart';
import '../repository/coach_request_repository.dart';

class GetAthletesUseCase {
  final CoachRequestRepository _repository;
  const GetAthletesUseCase(this._repository);

  TaskEither<Failure, AthleteSearchResult> call(String query, {int page = 1}) =>
      _repository.searchAthletes(query, page: page);
}
