import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/network/dio_error_message.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../model/active_task_model.dart';

class ActiveTasksResult {
  final List<ActiveTaskModel> tasks;
  final int totalRecords;

  const ActiveTasksResult({
    required this.tasks,
    required this.totalRecords,
  });
}

abstract interface class ActiveTasksRemoteDataSource {
  TaskEither<Failure, ActiveTasksResult> getActiveTasks({
    String status = 'in_progress',
    int page = 1,
  });

  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(int taskId);
}

class ActiveTasksRemoteDataSourceImpl implements ActiveTasksRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const ActiveTasksRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.coachToken);

  @override
  TaskEither<Failure, ActiveTasksResult> getActiveTasks({
    String status = 'in_progress',
    int page = 1,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/coach/my_athletes/active_tasks',
            queryParameters: {'status': status, 'page': page},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          // data: { athletes: [...], totalRecords: N, showPagination: [...] }
          final body = response.data;
          final data = body['data'];
          final List raw = (data?['athletes'] as List?) ?? [];
          final int total = (data?['totalRecords'] as num?)?.toInt() ?? 0;

          return right(ActiveTasksResult(
            tasks: raw
                .whereType<Map<String, dynamic>>()
                .map(ActiveTaskModel.fromJson)
                .toList(),
            totalRecords: total,
          ));
        } on DioException catch (e) {
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Failed to load active tasks'),
          ));
        } catch (e) {
          return left(ServerFailure('Failed to load active tasks: $e'));
        }
      });

  @override
  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(
          int taskId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/coach/athlete_task_results/$taskId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ??
                  'Result fetch karne mein failure',
            ));
          }

          final data = response.data['data'];
          final resultsList =
              (data is Map ? data['results'] : null) as List? ?? [];

          final sessions = resultsList
              .whereType<Map<String, dynamic>>()
              .map(CoachTaskResultSession.fromJson)
              .toList();

          return right(
              CoachTaskResultEntity(taskId: taskId, sessions: sessions));
        } on DioException catch (e) {
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Result fetch karne mein failure'),
          ));
        } catch (e) {
          return left(ServerFailure('Result fetch karne mein failure: $e'));
        }
      });
}
