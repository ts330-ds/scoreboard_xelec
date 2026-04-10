import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/sign_in_with_google_usecase.dart';
import '../../domain/usecase/sign_out_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;

  AuthCubit({
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
  })  : _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        super(const AuthState());

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _signInWithGoogle().run();
    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
      (user) => emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> signOut() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _signOut().run();
    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: AuthStatus.unauthenticated, user: null)),
    );
  }
}
