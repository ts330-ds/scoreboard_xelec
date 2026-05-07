import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/repository/coach_request_repository.dart';
import '../datasource/coach_request_remote_datasource.dart';

class CoachRequestRepositoryImpl implements CoachRequestRepository {
  final CoachRequestRemoteDataSource _dataSource;
  const CoachRequestRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, AthleteSearchResult> searchAthletes(String query, {int page = 1}) =>
      _dataSource.searchAthletes(query, page: page);

  @override
  TaskEither<Failure, void> sendAthleteRequest(int athleteId) =>
      _dataSource.sendAthleteRequest(athleteId);
}
