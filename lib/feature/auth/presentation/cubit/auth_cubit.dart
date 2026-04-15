import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/usecase/sign_in_with_google_usecase.dart';
import '../../domain/usecase/sign_in_with_linkedin_usecase.dart';
import '../../domain/usecase/sign_in_with_microsoft_usecase.dart';
import '../../domain/usecase/sign_in_with_apple_usecase.dart';
import '../../domain/usecase/sign_out_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithLinkedInUseCase _signInWithLinkedIn;
  final SignInWithMicrosoftUseCase _signInWithMicrosoft;
  final SignInWithAppleUseCase _signInWithApple;
  final SignOutUseCase _signOut;
  final SharedPreferences _pref;

  AuthCubit({
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignInWithLinkedInUseCase signInWithLinkedIn,
    required SignInWithMicrosoftUseCase signInWithMicrosoft,
    required SignInWithAppleUseCase signInWithApple,
    required SignOutUseCase signOut,
    required SharedPreferences pref,
  }) : _signInWithGoogle = signInWithGoogle,
       _signInWithLinkedIn = signInWithLinkedIn,
       _signInWithMicrosoft = signInWithMicrosoft,
       _signInWithApple = signInWithApple,
       _signOut = signOut,
       _pref = pref,
       super(const AuthState());

  Future<void> signInWithGoogle() =>
      _handleSignIn(() => _signInWithGoogle().run());

  Future<void> _handleSignIn(
    Future<dynamic> Function() signInCall,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signInCall();
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (user) async {
        await _pref.setString(PrefKeys.userEmail, user.email);
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      },
    );
  }

  Future<void> signInWithLinkedIn() =>
      _handleSignIn(() => _signInWithLinkedIn().run());

  Future<void> signInWithMicrosoft() =>
      _handleSignIn(() => _signInWithMicrosoft().run());

  Future<void> signInWithApple() =>
      _handleSignIn(() => _signInWithApple().run());

  Future<void> signOut() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _signOut().run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (_) =>
          emit(state.copyWith(status: AuthStatus.unauthenticated, user: null)),
    );
  }
}
