import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/sport.dart';
import '../../domain/repository/sport_repository.dart';
import '../source/sport_local_datasource.dart';
import '../source/sport_remote_datasource.dart';

class SportRepositoryImpl implements SportRepository {
  final SportRemoteDataSource _remote;
  final SportLocalDataSource _local;

  const SportRepositoryImpl(this._remote, this._local);

  @override
  TaskEither<Failure, List<Sport>> getSports() => TaskEither(() async {
        // Pehle cache check karo
        final isCacheValid = await _local.isCacheValid();
        if (isCacheValid) {
          final cached = await _local.getSports();
          if (cached != null) return right(cached);
        }
        final result = await _remote.getSports().run();
        return result.fold(
          (failure) => left(failure),
          (sports) async {
            await _local.saveSports(sports);
            return right(sports);
          },
        );
      });
}
