import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/task_result_entity.dart';
import '../model/athlete_task_model.dart';

abstract interface class AthleteTaskRemoteDataSource {
  TaskEither<Failure, AthleteTaskModel> createTask({
    required String name,
    required String duration,
    required String assignedBy,
  });

  TaskEither<Failure, List<AthleteTaskModel>> getMyTasks();

  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId);
}

class AthleteTaskRemoteDataSourceImpl implements AthleteTaskRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const AthleteTaskRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  @override
  TaskEither<Failure, AthleteTaskModel> createTask({
    required String name,
    required String duration,
    required String assignedBy,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.post(
            '/athlete/create_task',
            data: {
              'name': name,
              'duration': duration,
              'assigned_by': assignedBy,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Task create karne mein failure',
            ));
          }

          final taskJson = response.data['data'] as Map<String, dynamic>? ?? {};
          return right(AthleteTaskModel.fromJson(taskJson));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data?['message'] ?? e.message ?? 'Task create karne mein failure',
          ));
        } catch (e) {
          return left(ServerFailure('Task create karne mein failure: $e'));
        }
      });

  @override
  TaskEither<Failure, List<AthleteTaskModel>> getMyTasks() =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/athlete/my_tasks',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Tasks fetch karne mein failure',
            ));
          }

          final dataObj = response.data['data'];
          final list = dataObj is Map ? (dataObj['tasks'] ?? []) : [];
          return right((list as List)
              .whereType<Map<String, dynamic>>()
              .map(AthleteTaskModel.fromJson)
              .toList());
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data?['message'] ?? e.message ?? 'Tasks fetch karne mein failure',
          ));
        } catch (e) {
          return left(ServerFailure('Tasks fetch karne mein failure: $e'));
        }
      });

  @override
  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/athlete/task_results/$taskId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Result fetch karne mein failure',
            ));
          }

          final data = response.data['data'];
          final raw = data is Map<String, dynamic> ? data : {'response': data};
          return right(TaskResultEntity(taskId: taskId, raw: raw));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data?['message'] ?? e.message ?? 'Result fetch karne mein failure',
          ));
        } catch (e) {
          return left(ServerFailure('Result fetch karne mein failure: $e'));
        }
      });
}
