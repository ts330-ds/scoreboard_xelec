import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/athlete_search_model.dart';

class AthleteSearchResult {
  final List<AthleteSearchModel> athletes;
  final List<int> remainingPages;

  const AthleteSearchResult({
    required this.athletes,
    required this.remainingPages,
  });
}

abstract interface class CoachRequestRemoteDataSource {
  TaskEither<Failure, AthleteSearchResult> searchAthletes(String query, {int page = 1});
  TaskEither<Failure, void> sendAthleteRequest(int athleteId);
}

class CoachRequestRemoteDataSourceImpl implements CoachRequestRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const CoachRequestRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.coachToken);

  @override
  TaskEither<Failure, AthleteSearchResult> searchAthletes(String query, {int page = 1}) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }
        try {
          final params = <String, dynamic>{'page': page};
          if (query.trim().isNotEmpty) params['search'] = query.trim();

          final response = await _dio.get(
            '/coach/get/athletes',
            queryParameters: params,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          final data = response.data['data'] as Map<String, dynamic>;
          final List raw = data['athletes'] as List? ?? [];
          final List<int> showPagination = (data['showPagination'] as List? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((p) => p > page)
              .toList();

          final athletes = raw
              .map((e) => AthleteSearchModel.fromJson(e as Map<String, dynamic>))
              .toList();

          return right(AthleteSearchResult(
            athletes: athletes,
            remainingPages: showPagination,
          ));
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to load athletes',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to load athletes: $e'));
        }
      });

  @override
  TaskEither<Failure, void> sendAthleteRequest(int athleteId) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }
        try {
          final response = await _dio.post(
            '/coach/add_athlete_request/$athleteId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          if (response.data['success'] == false) {
            return left(ServerFailure(
              response.data['message'] ?? 'Failed to send request',
            ));
          }
          return right(null);
        } on DioException catch (e) {
          return left(ServerFailure(
            e.response?.data['message'] ?? e.message ?? 'Failed to send request',
          ));
        } catch (e) {
          return left(ServerFailure('Failed to send request: $e'));
        }
      });
}
