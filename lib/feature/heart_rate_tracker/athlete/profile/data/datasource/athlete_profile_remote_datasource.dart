import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/network/dio_error_message.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/athlete_profile_model.dart';

abstract interface class AthleteProfileRemoteDataSource {
  TaskEither<Failure, AthleteProfileModel> getProfile();

  TaskEither<Failure, AthleteProfileModel> updateProfile({
    required String name,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
    int? sportId,
    String? deviceModel,
    String? deviceSerial,
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
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/my_profile/athlete',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          return right(AthleteProfileModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Failed to fetch profile'),
          ));
        } catch (e) {
          return left(ServerFailure('Failed to fetch profile: $e'));
        }
      });

  @override
  TaskEither<Failure, AthleteProfileModel> updateProfile({
    required String name,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
    int? sportId,
    String? deviceModel,
    String? deviceSerial,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.put(
            '/my_profile/athlete',
            data: {
              'name': name,
              'phone_no': phone,
              'aadhar': aadhar,
              'dob': dob,
              'sex': sex,
              'dominant_hand': dominantHand,
              'height_in_feet': heightInFeet,
              'height_in_inches': heightInInches,
              'weight_in_kg': weightInKg,
              'weight_in_lbs': weightInLbs,
              'sport': sportId,
              'device_model': deviceModel,
              'device_serial': deviceSerial,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final success = response.data['success'] as bool? ?? false;
          if (!success) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to update profile',
            ));
          }
          // API returns data: null on success — return a placeholder; cubit will re-fetch
          return right(const AthleteProfileModel(id: 0, name: '', email: ''));
        } on DioException catch (e) {
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Failed to update profile'),
          ));
        } catch (e) {
          return left(ServerFailure('Failed to update profile: $e'));
        }
      });
}
