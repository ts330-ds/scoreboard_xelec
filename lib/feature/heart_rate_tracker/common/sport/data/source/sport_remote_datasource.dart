import 'package:flutter/foundation.dart';
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
          // Page 1 hit karke pagination metadata padho. Agar zyada pages
          // hain to baki pages parallel fetch karke combine kar denge.
          // Local cache (24h) wala layer repository handle karta hai —
          // yeh sirf saari pages ek baar me network se laata hai.
          final firstPage = await _fetchPage(1);
          final firstSports = firstPage.sports;
          final pageNumbers = firstPage.pageNumbers;

          if (pageNumbers.length <= 1) {
            return right(firstSports);
          }

          final remainingPages = pageNumbers.where((p) => p != 1).toList();
          debugPrint(
              '[SPORTS API] page 1 done — fetching ${remainingPages.length} more page(s) in parallel');

          final rest = await Future.wait(remainingPages.map(_fetchPage));
          final combined = <SportModel>[
            ...firstSports,
            for (final p in rest) ...p.sports,
          ];
          debugPrint('[SPORTS API] total fetched: ${combined.length}');
          return right(combined);
        } catch (e) {
          return left(SportFailure('Failed to fetch sports: $e'));
        }
      });

  Future<_SportsPage> _fetchPage(int page) async {
    final response = await _apiService.dio.get(
      '/common/sports',
      queryParameters: {'page': page,'limit': 100},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final sportsData = data['sports'] as List<dynamic>;
    final sports = sportsData
        .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pages = (data['showPagination'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[];
    return _SportsPage(sports: sports, pageNumbers: pages);
  }
}

class _SportsPage {
  final List<SportModel> sports;
  final List<int> pageNumbers;
  const _SportsPage({required this.sports, required this.pageNumbers});
}
