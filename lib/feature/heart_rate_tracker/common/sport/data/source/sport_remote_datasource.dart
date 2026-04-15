import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import '../model/sport_model.dart';

abstract interface class SportRemoteDataSource {
  TaskEither<Failure, List<SportModel>> getSports();
}

class SportRemoteDataSourceImpl implements SportRemoteDataSource {
  final ApiService _apiService;

  const SportRemoteDataSourceImpl(this._apiService);

  @override
  TaskEither<Failure, List<SportModel>> getSports() => TaskEither(() async {
        try {
          final response = await _apiService.dio.get('/api/v1/common/sports');
          final List<dynamic> sportsData =
              response.data['data']['sports'] as List<dynamic>;
          final sports = sportsData
              .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return right(sports);
        } catch (e) {
          return left(SportFailure('Failed to fetch sports: $e'));
        }
      });
}
