import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/athlete_profile_model.dart';

abstract interface class AthleteProfileRemoteDataSource {
  TaskEither<Failure, AthleteProfileModel> getProfile();

  TaskEither<Failure, AthleteProfileModel> updateProfile({
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  });
}

class AthleteProfileRemoteDataSourceImpl
    implements AthleteProfileRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const AthleteProfileRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.userToken);

  @override
  TaskEither<Failure, AthleteProfileModel> getProfile() =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.get(
            '/my_profile/athlete',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
          return right(AthleteProfileModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(
            ServerFailure(
              e.response?.data['message'] ?? e.message ?? 'Failed to fetch profile',
            ),
          );
        } catch (e) {
          return left(ServerFailure('Failed to fetch profile: $e'));
        }
      });

  @override
  TaskEither<Failure, AthleteProfileModel> updateProfile({
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token nahi mila, dobara login karein'));
        }

        try {
          final response = await _dio.put(
            '/athlete/profile',
            data: {
              if (name != null) 'name': name,
              if (phone != null) 'phone': phone,
              if (age != null) 'age': age,
              if (gender != null) 'gender': gender,
              if (sportId != null) 'sport_id': sportId,
            },
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
          return right(AthleteProfileModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(
            ServerFailure(
              e.response?.data['message'] ?? e.message ?? 'Failed to update profile',
            ),
          );
        } catch (e) {
          return left(ServerFailure('Failed to update profile: $e'));
        }
      });
}
