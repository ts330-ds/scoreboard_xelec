import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../model/active_task_model.dart';

abstract interface class ActiveTasksRemoteDataSource {
  TaskEither<Failure, List<ActiveTaskModel>> getActiveTasks({
    String status = 'in_progress',
  });

  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(int taskId);
}

class ActiveTasksRemoteDataSourceImpl implements ActiveTasksRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const ActiveTasksRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.coachToken);

  @override
  TaskEither<Failure, List<ActiveTaskModel>> getActiveTasks({
    String status = 'in_progress',
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/coach/my_athletes/active_tasks',
            queryParameters: {'status': status},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          final List raw = (body['data']?['athletes'] as List?) ?? [];

          return right(
            raw
                .whereType<Map<String, dynamic>>()
                .map(ActiveTaskModel.fromJson)
                .toList(),
          );
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data?['message'] ??
                e.message ??
                'Active tasks load nahi ho sakey',
          ));
        } catch (e) {
          return left(ServerFailure('Active tasks load nahi ho sakey: $e'));
        }
      });

  @override
  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(
          int taskId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
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
            e.response?.data?['message'] ??
                e.message ??
                'Result fetch karne mein failure',
          ));
        } catch (e) {
          return left(ServerFailure('Result fetch karne mein failure: $e'));
        }
      });
}
