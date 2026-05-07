import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/health_metrics_model.dart';

abstract interface class HealthMetricsDatasource {
  TaskEither<Failure, HealthMetricsModel> getHealthMetrics({
    required int athleteId,
    required String fromDate,
    required String toDate,
  });
}

class HealthMetricsDatasourceImpl implements HealthMetricsDatasource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const HealthMetricsDatasourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  @override
  TaskEither<Failure, HealthMetricsModel> getHealthMetrics({
    required int athleteId,
    required String fromDate,
    required String toDate,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/coach/health_metrics/$athleteId',
            queryParameters: {
              'from_date': fromDate,
              'to_date': toDate,
            },
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );

          if (response.data['success'] == false) {
            return left(
              ServerFailure(
                response.data['message'] ?? 'Health metrics fetch failed',
              ),
            );
          }

          return right(HealthMetricsModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(
            ServerFailure(
              e.response?.data['message'] ??
                  e.message ??
                  'Failed to fetch health metrics',
            ),
          );
        } catch (e) {
          return left(ServerFailure('Failed to fetch health metrics: $e'));
        }
      });
}
