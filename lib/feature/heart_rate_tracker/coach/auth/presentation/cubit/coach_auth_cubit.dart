import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/usecase/login_coach_usecase.dart';
import '../../domain/usecase/login_coach_with_social_usecase.dart';
import '../../domain/usecase/logout_coach_usecase.dart';
import '../../domain/usecase/register_coach_usecase.dart';
import 'coach_auth_state.dart';

class CoachAuthCubit extends Cubit<CoachAuthState> {
  final LoginCoachUseCase _login;
  final LoginCoachWithSocialUseCase _loginWithSocial;
  final RegisterCoachUseCase _register;
  final LogoutCoachUseCase _logout;

  CoachAuthCubit({
    required LoginCoachUseCase login,
    required LoginCoachWithSocialUseCase loginWithSocial,
    required RegisterCoachUseCase register,
    required LogoutCoachUseCase logout,
  })  : _login = login,
        _loginWithSocial = loginWithSocial,
        _register = register,
        _logout = logout,
        super(const CoachAuthState());

  Future<void> login({required String email, required String password}) async {
    debugPrint('CoachAuthCubit: login called — email: $email');
    emit(state.copyWith(status: CoachAuthStatus.loading));
    final result = await _login(email: email, password: password).run();
    result.fold(
      (failure) => _handleLoginFailure(failure),
      (coach) {
        sl<ApiService>().setAuthToken(coach.token);
        emit(state.copyWith(status: CoachAuthStatus.authenticated, coach: coach));
      },
    );
  }

  Future<void> loginWithSocialAuth({required String email}) async {
    debugPrint('CoachAuthCubit: loginWithSocialAuth called — email: $email');
    emit(state.copyWith(status: CoachAuthStatus.loading));
    final result = await _loginWithSocial(email: email).run();
    result.fold(
      (failure) => _handleLoginFailure(failure),
      (coach) {
        sl<ApiService>().setAuthToken(coach.token);
        emit(state.copyWith(status: CoachAuthStatus.authenticated, coach: coach));
      },
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  }) async {
    emit(state.copyWith(status: CoachAuthStatus.loading));
    final result = await _register(
      name: name,
      email: email,
      password: password,
      sport: sport,
      organization: organization,
    ).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachAuthStatus.error,
        errorMessage: failure.message,
      )),
      (coach) {
        sl<ApiService>().setAuthToken(coach.token);
        emit(state.copyWith(status: CoachAuthStatus.authenticated, coach: coach));
      },
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: CoachAuthStatus.loggingOut));
    final result = await _logout().run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: CoachAuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        sl<ApiService>().clearAuthToken();
        emit(state.copyWith(status: CoachAuthStatus.loggedOut));
      },
    );
  }

  void _handleLoginFailure(Failure failure) {
    if (failure is CoachNotFoundFailure) {
      emit(state.copyWith(status: CoachAuthStatus.notRegistered));
    } else {
      emit(state.copyWith(
        status: CoachAuthStatus.error,
        errorMessage: failure.message,
      ));
    }
  }
}
