import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/athlete_health_metrics_entity.dart';
import '../model/my_athlete_model.dart';

class MyAthletesResult {
  final List<MyAthleteModel> athletes;
  final int totalRecords;

  const MyAthletesResult({
    required this.athletes,
    required this.totalRecords,
  });
}

abstract interface class MyAthletesRemoteDataSource {
  TaskEither<Failure, MyAthletesResult> getMyAthletes({
    String? search,
    int page = 1,
  });

  TaskEither<Failure, MyAthleteModel> getAthleteDetail(int athleteId);

  TaskEither<Failure, void> removeAthlete(int athleteId);

  TaskEither<Failure, AthleteHealthMetricsEntity> getHealthMetrics({
    required int athleteId,
    required DateTime fromDate,
    required DateTime toDate,
  });
}

class MyAthletesRemoteDataSourceImpl implements MyAthletesRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const MyAthletesRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.coachToken);

  @override
  TaskEither<Failure, MyAthletesResult> getMyAthletes({
    String? search,
    int page = 1,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final params = <String, dynamic>{'page': page};
          if (search != null && search.trim().isNotEmpty) {
            params['search'] = search.trim();
          }

          final response = await _dio.get(
            '/coach/my_athletes',
            queryParameters: params,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          // data: { athletes: [...], totalRecords: N, showPagination: [...] }
          final Map<String, dynamic> data =
              response.data['data'] as Map<String, dynamic>;
          final List raw = data['athletes'] as List? ?? [];
          final int total = (data['totalRecords'] as num?)?.toInt() ?? 0;

          return right(MyAthletesResult(
            athletes: raw
                .map((e) => MyAthleteModel.fromJson(e as Map<String, dynamic>))
                .toList(),
            totalRecords: total,
          ));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ??
                e.message ??
                'Failed to load athletes',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to load athletes: $e'));
        }
      });

  @override
  TaskEither<Failure, MyAthleteModel> getAthleteDetail(int athleteId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/coach/get_athlete/$athleteId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final Map<String, dynamic> data =
              response.data['data'] as Map<String, dynamic>;
          return right(MyAthleteModel.fromDetailJson(data));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to load athlete detail',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to load athlete detail: $e'));
        }
      });

  @override
  TaskEither<Failure, void> removeAthlete(int athleteId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.delete(
            '/coach/remove_athlete/$athleteId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final success = response.data['success'] as bool? ?? false;
          if (!success) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to remove athlete',
            ));
          }
          return right(null);
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to remove athlete',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to remove athlete: $e'));
        }
      });

  @override
  TaskEither<Failure, AthleteHealthMetricsEntity> getHealthMetrics({
    required int athleteId,
    required DateTime fromDate,
    required DateTime toDate,
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
              'from_date': _formatDate(fromDate),
              'to_date': _formatDate(toDate),
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final dynamic data = response.data['data'] ?? response.data;
          final Map<String, dynamic> raw = data is Map<String, dynamic>
              ? data
              : {'response': data};

          return right(AthleteHealthMetricsEntity(raw: raw));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ??
                e.message ??
                'Failed to load health metrics',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to load health metrics: $e'));
        }
      });

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
