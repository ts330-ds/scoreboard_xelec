import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/network/dio_error_message.dart';
import '../model/athlete_auth_model.dart';

abstract interface class AthleteAuthRemoteDataSource {
  TaskEither<Failure, AthleteAuthModel> login({
    required String email,
    required String password,
  });

  TaskEither<Failure, AthleteAuthModel> loginWithSocial({
    required String email,
  });

  TaskEither<Failure, AthleteAuthModel> register({
    required String name,
    required String email,
    required String password,
    required int sport,
  });
}

class AthleteAuthRemoteDataSourceImpl implements AthleteAuthRemoteDataSource {
  final Dio _dio;

  const AthleteAuthRemoteDataSourceImpl(this._dio);

  @override
  TaskEither<Failure, AthleteAuthModel> login({
    required String email,
    required String password,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/athlete/login',
            data: {
              'email': email,
              'password': password,
            },
          );
          debugPrint('Login response: ${response.data}');

          if (response.data['success'] == false) {
            return left(AuthFailure(response.data['message'] ?? 'Login failed'));
          }

          return right(AthleteAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          debugPrint('Login DioException type: ${e.type}');
          debugPrint('Login DioException: ${e.response?.statusCode} ${e.response?.data}');
          if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
            return left(const AthleteNotFoundFailure());
          }
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Login failed')));
        } catch (e) {
          debugPrint('Login error: $e');
          return left(AuthFailure('Login failed: $e'));
        }
      });

  @override
  TaskEither<Failure, AthleteAuthModel> loginWithSocial({
    required String email,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/athlete/social-login',
            data: {'email': email},
          );
          debugPrint('Social login response: ${response.data}');

          if (response.data['success'] == false) {
            return left(AuthFailure(response.data['message'] ?? 'Login failed'));
          }

          return right(AthleteAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          debugPrint('Social login DioException: ${e.response?.statusCode} ${e.response?.data}');
          if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
            return left(const AthleteNotFoundFailure());
          }
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Login failed')));
        } catch (e) {
          debugPrint('Social login error: $e');
          return left(AuthFailure('Login failed: $e'));
        }
      });

  @override
  TaskEither<Failure, AthleteAuthModel> register({
    required String name,
    required String email,
    required String password,
    required int sport,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/athlete/register',
            data: {
              'name': name,
              'email': email,
              'password': password,
              'sport': sport,
            },
          );
          return right(AthleteAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Registration failed')));
        } catch (e) {
          return left(AuthFailure('Registration failed: $e'));
        }
      });
}
