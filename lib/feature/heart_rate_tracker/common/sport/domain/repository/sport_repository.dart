import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/sport.dart';

abstract interface class SportRepository {
  TaskEither<Failure, List<Sport>> getSports();
}
