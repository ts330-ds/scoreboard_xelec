import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/network/dio_error_message.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/coach_profile_model.dart';

abstract interface class CoachProfileRemoteDataSource {
  TaskEither<Failure, CoachProfileModel> getProfile();

  TaskEither<Failure, CoachProfileModel> updateProfile({
    required String name,
    required String organization,
    required int sport,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
  });
}

class CoachProfileRemoteDataSourceImpl implements CoachProfileRemoteDataSource {
  final Dio _dio;
  final SharedPreferences _prefs;

  const CoachProfileRemoteDataSourceImpl(this._dio, this._prefs);

  String? get _token => _prefs.getString(PrefKeys.coachToken);

  @override
  TaskEither<Failure, CoachProfileModel> getProfile() =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final response = await _dio.get(
            '/my_profile/coach',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          return right(CoachProfileModel.fromJson(response.data));
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            return left(const AuthFailure('Session expired, please login again'));
          }
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Failed to fetch profile'),
          ));
        } catch (e) {
          return left(ServerFailure('Failed to fetch profile: $e'));
        }
      });

  @override
  TaskEither<Failure, CoachProfileModel> updateProfile({
    required String name,
    required String organization,
    required int sport,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
  }) =>
      TaskEither(() async {
        final token = _token;
        if (token == null || token.isEmpty) {
          return left(const AuthFailure('Token not found, please login again'));
        }

        try {
          final Map<String, dynamic> payload = {
            'name': name,
            'organization': organization,
            'sport': sport,
          };
          if (phone != null) payload['phone_no'] = phone;
          if (aadhar != null) payload['aadhar'] = aadhar;
          if (dob != null) payload['dob'] = dob;
          if (sex != null) payload['sex'] = sex;
          if (dominantHand != null) payload['dominant_hand'] = dominantHand;
          if (heightInFeet != null) payload['height_in_feet'] = heightInFeet;
          if (heightInInches != null) payload['height_in_inches'] = heightInInches;
          if (weightInKg != null) payload['weight_in_kg'] = weightInKg;
          if (weightInLbs != null) payload['weight_in_lbs'] = weightInLbs;

          final response = await _dio.put(
            '/my_profile/coach',
            data: payload,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final success = response.data['success'] as bool? ?? false;
          if (!success) {
            return left(ServerFailure(
              response.data['message'] as String? ?? 'Failed to update profile',
            ));
          }
          return right(const CoachProfileModel(name: '', email: ''));
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            return left(const AuthFailure('Session expired, please login again'));
          }
          return left(ServerFailure(
            friendlyDioMessage(e, fallback: 'Failed to update profile'),
          ));
        } catch (e) {
          return left(ServerFailure('Failed to update profile: $e'));
        }
      });
}
