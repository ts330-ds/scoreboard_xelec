import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/coach_request_entity.dart';
import '../../domain/repository/athlete_notification_repository.dart';
import '../datasource/athlete_notification_remote_datasource.dart';

class AthleteNotificationRepositoryImpl
    implements AthleteNotificationRepository {
  final AthleteNotificationRemoteDataSource _dataSource;

  const AthleteNotificationRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, List<CoachRequestEntity>> getCoachRequests() =>
      _dataSource.getCoachRequests();

  @override
  TaskEither<Failure, String> acceptRequest(int requestId) =>
      _dataSource.acceptRequest(requestId);

  @override
  TaskEither<Failure, String> rejectRequest(int requestId) =>
      _dataSource.rejectRequest(requestId);
}
