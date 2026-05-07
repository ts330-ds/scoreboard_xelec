import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/coach_request_remote_datasource.dart';

abstract interface class CoachRequestRepository {
  TaskEither<Failure, AthleteSearchResult> searchAthletes(String query, {int page});
  TaskEither<Failure, void> sendAthleteRequest(int athleteId);
}
