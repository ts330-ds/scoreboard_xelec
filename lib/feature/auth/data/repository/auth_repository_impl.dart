import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/auth_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, AuthUser> signInWithGoogle() =>
      _dataSource.signInWithGoogle();

  @override
  TaskEither<Failure, Unit> signOut() => _dataSource.signOut();
}
