import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/usecase/login_athlete_usecase.dart';
import '../../domain/usecase/logout_athlete_usecase.dart';
import '../../domain/usecase/register_athlete_usecase.dart';
import 'athlete_auth_state.dart';

class AthleteAuthCubit extends Cubit<AthleteAuthState> {
  final LoginAthleteUseCase _login;
  final RegisterAthleteUseCase _register;
  final LogoutAthleteUseCase _logout;

  AthleteAuthCubit({
    required LoginAthleteUseCase login,
    required RegisterAthleteUseCase register,
    required LogoutAthleteUseCase logout,
  }) : _login = login,
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
        emit(state.copyWith(
          status: AthleteAuthStatus.authenticated,
          athlete: athlete,
        ));
      },
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AthleteAuthStatus.loggingOut));
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
