import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/health_monitor/presentation/cubit/athlete_health_monitor_cubit.dart';
import '../../domain/usecase/login_athlete_usecase.dart';
import '../../domain/usecase/login_athlete_with_social_usecase.dart';
import '../../domain/usecase/logout_athlete_usecase.dart';
import '../../domain/usecase/register_athlete_usecase.dart';
import 'athlete_auth_state.dart';

class AthleteAuthCubit extends Cubit<AthleteAuthState> {
  final LoginAthleteUseCase _login;
  final LoginAthleteWithSocialUseCase _loginWithSocial;
  final RegisterAthleteUseCase _register;
  final LogoutAthleteUseCase _logout;

  AthleteAuthCubit({
    required LoginAthleteUseCase login,
    required LoginAthleteWithSocialUseCase loginWithSocial,
    required RegisterAthleteUseCase register,
    required LogoutAthleteUseCase logout,
  }) : _login = login,
       _loginWithSocial = loginWithSocial,
       _register = register,
       _logout = logout,
       super(const AthleteAuthState());

  Future<void> login({required String email, required String password}) async {
    debugPrint('AthleteAuthCubit: login called — email: $email');
    emit(state.copyWith(status: AthleteAuthStatus.loading));
    final result = await _login(email: email, password: password).run();
    result.fold(
      (failure) => _handleLoginFailure(failure),
      (athlete) {
        sl<ApiService>().setAuthToken(athlete.token);
        // Cubit warm-up — UI banners ka listener register ho jaye early.
        sl<AthleteHealthMonitorCubit>();
        emit(state.copyWith(
          status: AthleteAuthStatus.authenticated,
          athlete: athlete,
        ));
      },
    );
  }

  Future<void> loginWithSocialAuth({required String email}) async {
    debugPrint('AthleteAuthCubit: loginWithSocialAuth called — email: $email');
    emit(state.copyWith(status: AthleteAuthStatus.loading));
    final result = await _loginWithSocial(email: email).run();
    result.fold(
      (failure) => _handleLoginFailure(failure),
      (athlete) {
        sl<ApiService>().setAuthToken(athlete.token);
        // Cubit warm-up — UI banners ka listener register ho jaye early.
        sl<AthleteHealthMonitorCubit>();
        emit(state.copyWith(
          status: AthleteAuthStatus.authenticated,
          athlete: athlete,
        ));
      },
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int sport,
  }) async {
    emit(state.copyWith(status: AthleteAuthStatus.loading));
    final result = await _register(
      name: name,
      email: email,
      password: password,
      sport: sport,
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AthleteAuthStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (athlete) {
        sl<ApiService>().setAuthToken(athlete.token);
        // Cubit warm-up — UI banners ka listener register ho jaye early.
        sl<AthleteHealthMonitorCubit>();
        emit(state.copyWith(
          status: AthleteAuthStatus.authenticated,
          athlete: athlete,
        ));
      },
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AthleteAuthStatus.loggingOut));

    final bleCubit = sl<HeartBleCubit>();
    if (bleCubit.state.isConnected) {
      await bleCubit.disconnect();
    }

    final result = await _logout().run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteAuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        sl<ApiService>().clearAuthToken();
        emit(state.copyWith(status: AthleteAuthStatus.loggedOut));
      },
    );
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(status: AthleteAuthStatus.loggingOut));

    final bleCubit = sl<HeartBleCubit>();
    if (bleCubit.state.isConnected) {
      await bleCubit.disconnect();
    }

    try {
      final api = sl<ApiService>();
      final response = await api.dio.delete('/athlete/delete_account');
      final data = response.data as Map<String, dynamic>? ?? {};

      if (data['success'] == true) {
        api.clearAuthToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        emit(state.copyWith(status: AthleteAuthStatus.loggedOut));
      } else {
        final msg = data['message']?.toString() ?? 'Delete failed';
        emit(state.copyWith(
          status: AthleteAuthStatus.error,
          errorMessage: msg,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AthleteAuthStatus.error,
        errorMessage: 'Failed to delete account: $e',
      ));
    }
  }

  // Agar login mein 404 aaye — user registered nahi hai
  void _handleLoginFailure(Failure failure) {
    if (failure is AthleteNotFoundFailure) {
      emit(state.copyWith(status: AthleteAuthStatus.notRegistered));
    } else {
      emit(
        state.copyWith(
          status: AthleteAuthStatus.error,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
