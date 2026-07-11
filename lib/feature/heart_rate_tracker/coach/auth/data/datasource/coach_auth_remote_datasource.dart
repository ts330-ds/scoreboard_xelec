import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/network/dio_error_message.dart';
import '../model/coach_auth_model.dart';

abstract interface class CoachAuthRemoteDataSource {
  TaskEither<Failure, CoachAuthModel> login({
    required String email,
    required String password,
  });

  TaskEither<Failure, CoachAuthModel> loginWithSocial({
    required String email,
  });

  TaskEither<Failure, CoachAuthModel> register({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  });
}

class CoachAuthRemoteDataSourceImpl implements CoachAuthRemoteDataSource {
  final Dio _dio;

  const CoachAuthRemoteDataSourceImpl(this._dio);

  @override
  TaskEither<Failure, CoachAuthModel> login({
    required String email,
    required String password,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/coach/login',
            data: {'email': email, 'password': password},
          );
          debugPrint('Coach login response: ${response.data}');

          if (response.data['success'] == false) {
            return left(AuthFailure(response.data['message'] ?? 'Login failed'));
          }

          return right(CoachAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          debugPrint('Coach login DioException: ${e.response?.statusCode} ${e.response?.data}');
          if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
            return left(const CoachNotFoundFailure());
          }
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Login failed')));
        } catch (e) {
          return left(AuthFailure('Login failed: $e'));
        }
      });

  @override
  TaskEither<Failure, CoachAuthModel> loginWithSocial({
    required String email,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/coach/social-login',
            data: {'email': email},
          );
          debugPrint('Coach social login response: ${response.data}');

          if (response.data['success'] == false) {
            return left(AuthFailure(response.data['message'] ?? 'Login failed'));
          }

          return right(CoachAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          debugPrint('Coach social login DioException: ${e.response?.statusCode} ${e.response?.data}');
          if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
            return left(const CoachNotFoundFailure());
          }
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Login failed')));
        } catch (e) {
          return left(AuthFailure('Login failed: $e'));
        }
      });

  @override
  TaskEither<Failure, CoachAuthModel> register({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  }) =>
      TaskEither(() async {
        try {
          final response = await _dio.post(
            '/auth/coach/register',
            data: {
              'name': name,
              'email': email,
              'password': password,
              'sport': sport,
              'organization': organization,
            },
          );
          return right(CoachAuthModel.fromJson(response.data));
        } on DioException catch (e) {
          return left(AuthFailure(friendlyDioMessage(e, fallback: 'Registration failed')));
        } catch (e) {
          return left(AuthFailure('Registration failed: $e'));
        }
      });
}
