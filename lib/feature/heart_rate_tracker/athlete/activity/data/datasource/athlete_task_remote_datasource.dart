import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/task_result_entity.dart';
import '../model/athlete_task_model.dart';

class MyTasksResult {
  final List<AthleteTaskModel> tasks;
  final int totalRecords;

  const MyTasksResult({
    required this.tasks,
    required this.totalRecords,
  });
}

abstract interface class AthleteTaskRemoteDataSource {
  TaskEither<Failure, AthleteTaskModel> createTask({
    required String name,
    required String assignedBy,
  });

  TaskEither<Failure, MyTasksResult> getMyTasks({int page = 1});

  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId);

  /// Upload a chunk of session readings to the server.
  TaskEither<Failure, bool> submitTaskResults({
    required int taskId,
    required bool isFirstChunk,
    required bool isLastChunk,
    required List<Map<String, dynamic>> readings,
  });
}

class AthleteTaskRemoteDataSourceImpl implements AthleteTaskRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const AthleteTaskRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  static String _extractErrorMessage(
    Map<String, dynamic>? body,
    String fallback,
  ) {
    if (body == null) return fallback;
    final message = body['message'] as String? ?? fallback;
    final errors = body['errors'];
    if (errors == null) return message;

    // errors can be Map<String, List> or List<String>
    final parts = <String>[];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final msgs = entry.value;
        if (msgs is List && msgs.isNotEmpty) {
          parts.add('${entry.key}: ${msgs.join(', ')}');
        }
      }
    } else if (errors is List) {
      for (final e in errors) {
        if (e is String) parts.add(e);
      }
    }
    return parts.isNotEmpty ? parts.join('\n') : message;
  }

  @override
  TaskEither<Failure, AthleteTaskModel> createTask({
    required String name,
    required String assignedBy,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.post(
            '/athlete/create_task',
            data: {
              'name': name,
              'assigned_by': assignedBy,
              // Backend "Session duration is required (in minutes)" maangta hai.
              // Default 720 min (12h) bhej rahe hain.
              'duration': 720,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          if (body is Map<String, dynamic> && body['success'] == false) {
            return left(ServerFailure(
              _extractErrorMessage(body, 'Task create karne mein failure'),
            ));
          }

          final taskJson = (body is Map<String, dynamic>
                  ? body['data'] as Map<String, dynamic>?
                  : null) ??
              {};
          return right(AthleteTaskModel.fromJson(taskJson));
        } on DioException catch (e) {
          final data = e.response?.data;
          final body = data is Map<String, dynamic> ? data : null;
          return left(ServerFailure(
            _extractErrorMessage(
              body,
              e.message ?? 'Task create karne mein failure',
            ),
          ));
        } catch (e) {
          return left(ServerFailure('Task create karne mein failure: $e'));
        }
      });

  @override
  TaskEither<Failure, MyTasksResult> getMyTasks({int page = 1}) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/athlete/my_tasks',
            queryParameters: {'page': page},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          if (body == null || body is! Map<String, dynamic>) {
            return left(const ServerFailure('Invalid response from server'));
          }

          if (body['success'] == false) {
            return left(ServerFailure(
              _extractErrorMessage(body, 'Tasks fetch karne mein failure'),
            ));
          }

          final dataObj = body['data'];
          final list = dataObj is Map ? (dataObj['tasks'] ?? []) : [];
          if (list is! List) {
            return left(const ServerFailure('Unexpected task list format'));
          }
          final total = dataObj is Map
              ? (dataObj['totalRecords'] as num?)?.toInt() ?? 0
              : 0;
          return right(MyTasksResult(
            tasks: list
                .whereType<Map<String, dynamic>>()
                .map(AthleteTaskModel.fromJson)
                .toList(),
            totalRecords: total,
          ));
        } on DioException catch (e) {
          final data = e.response?.data;
          final body = data is Map<String, dynamic> ? data : null;
          return left(ServerFailure(
            _extractErrorMessage(
              body,
              e.message ?? 'Tasks fetch karne mein failure',
            ),
          ));
        } catch (e) {
          return left(ServerFailure('Tasks fetch karne mein failure: $e'));
        }
      });

  @override
  TaskEither<Failure, bool> submitTaskResults({
    required int taskId,
    required bool isFirstChunk,
    required bool isLastChunk,
    required List<Map<String, dynamic>> readings,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.post(
            '/athlete/task_results/submit',
            data: {
              'task_id': taskId,
              'is_first_chunk': isFirstChunk,
              'is_last_chunk': isLastChunk,
              'readings': readings,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          if (body is! Map<String, dynamic>) {
            return left(ServerFailure(
              'Unexpected response format: ${body.runtimeType}',
            ));
          }
          if (body['success'] == false) {
            return left(ServerFailure(
              _extractErrorMessage(body, 'Upload failed'),
            ));
          }

          debugPrint('[UPLOAD] Chunk OK — task=$taskId '
              'first=$isFirstChunk last=$isLastChunk '
              'readings=${readings.length}');
          return right(true);
        } on DioException catch (e) {
          final data = e.response?.data;
          final body = data is Map<String, dynamic> ? data : null;
          return left(ServerFailure(
            _extractErrorMessage(body, e.message ?? 'Upload failed'),
          ));
        } catch (e) {
          return left(ServerFailure('Upload failed: $e'));
        }
      });

  @override
  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/athlete/task_results/$taskId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final body = response.data;
          if (body is Map<String, dynamic> && body['success'] == false) {
            return left(ServerFailure(
              _extractErrorMessage(body, 'Result fetch karne mein failure'),
            ));
          }

          final taskData = body is Map<String, dynamic> ? body['data'] : null;
          final raw = taskData is Map<String, dynamic>
              ? taskData
              : {'response': taskData};
          return right(TaskResultEntity(taskId: taskId, raw: raw));
        } on DioException catch (e) {
          final data = e.response?.data;
          final errBody = data is Map<String, dynamic> ? data : null;
          return left(ServerFailure(
            _extractErrorMessage(
              errBody,
              e.message ?? 'Result fetch karne mein failure',
            ),
          ));
        } catch (e) {
          return left(ServerFailure('Result fetch karne mein failure: $e'));
        }
      });
}
