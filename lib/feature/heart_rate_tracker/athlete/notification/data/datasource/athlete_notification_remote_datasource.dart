import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/coach_request_model.dart';

abstract interface class AthleteNotificationRemoteDataSource {
  TaskEither<Failure, List<CoachRequestModel>> getCoachRequests();
  TaskEither<Failure, String> acceptRequest(int requestId);
  TaskEither<Failure, String> rejectRequest(int requestId);
}

class AthleteNotificationRemoteDataSourceImpl
    implements AthleteNotificationRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const AthleteNotificationRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  /// Maps a [DioException] to a user-friendly message, with explicit handling
  /// for timeouts and connection errors so the UI can show a clean retry.
  String _dioMessage(DioException e, String fallback) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
        return e.message ?? fallback;
    }
  }

  /// Returns the server-provided message when the response signals failure,
  /// otherwise null. Tolerates non-Map / unexpected bodies.
  String? _failureMessage(dynamic body, String fallback) {
    if (body is! Map) return fallback;
    if (body['success'] == false) {
      final msg = body['message'];
      return msg is String ? msg : fallback;
    }
    return null;
  }

  @override
  TaskEither<Failure, List<CoachRequestModel>> getCoachRequests() =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/athlete/list/requests',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final failure =
              _failureMessage(response.data, 'Failed to fetch requests');
          if (failure != null) return left(ServerFailure(failure));

          final data = response.data;
          final rawList = (data is Map ? data['data'] : null) is Map
              ? (data['data'] as Map)['requests']
              : null;

          if (rawList is! List) return right(<CoachRequestModel>[]);

          final requests = rawList
              .whereType<Map<String, dynamic>>()
              .map(CoachRequestModel.fromJson)
              .toList();

          return right(requests);
        } on DioException catch (e) {
          return left(ServerFailure(_dioMessage(e, 'Failed to fetch requests')));
        } catch (e) {
          return left(const ServerFailure('Something went wrong while loading requests'));
        }
      });

  @override
  TaskEither<Failure, String> acceptRequest(int requestId) =>
      _respond(requestId, 'approved', 'Request approved successfully',
          'Failed to accept request');

  @override
  TaskEither<Failure, String> rejectRequest(int requestId) =>
      _respond(requestId, 'rejected', 'Request rejected successfully',
          'Failed to reject request');

  TaskEither<Failure, String> _respond(
    int requestId,
    String action,
    String successFallback,
    String errorFallback,
  ) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.put(
            '/athlete/request_action/$requestId',
            data: {"action": action},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final failure = _failureMessage(response.data, errorFallback);
          if (failure != null) return left(ServerFailure(failure));

          final data = response.data;
          final msg = data is Map ? data['message'] : null;
          return right(msg is String ? msg : successFallback);
        } on DioException catch (e) {
          return left(ServerFailure(_dioMessage(e, errorFallback)));
        } catch (e) {
          return left(ServerFailure(errorFallback));
        }
      });
}
