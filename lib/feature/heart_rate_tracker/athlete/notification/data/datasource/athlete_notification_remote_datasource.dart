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

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to fetch requests',
            ));
          }

          final requests = (response.data['data']['requests'] as List)
              .map((e) => CoachRequestModel.fromJson(e as Map<String, dynamic>))
              .toList();

          return right(requests);
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to fetch requests',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to fetch requests: $e'));
        }
      });

  @override
  TaskEither<Failure, String> acceptRequest(int requestId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.put(
            '/athlete/request_action/$requestId',
            data: {"action": "approved"},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to accept request',
            ));
          }

          return right(response.data['message'] as String? ?? 'Request approved successfully');
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to accept request',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to accept request: $e'));
        }
      });

  @override
  TaskEither<Failure, String> rejectRequest(int requestId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.put(
            '/athlete/request_action/$requestId',
            data: {"action": "rejected"},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to reject request',
            ));
          }

          return right(response.data['message'] as String? ?? 'Request rejected successfully');
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to reject request',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to reject request: $e'));
        }
      });
}
