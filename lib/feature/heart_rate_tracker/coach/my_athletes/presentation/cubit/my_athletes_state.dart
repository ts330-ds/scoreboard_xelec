import 'package:equatable/equatable.dart';
import '../../domain/entity/my_athlete_entity.dart';

enum MyAthletesStatus { initial, loading, loadingMore, loaded, empty, error }

class MyAthletesState extends Equatable {
  final MyAthletesStatus status;
  final List<MyAthleteEntity> athletes;
  final String? errorMessage;
  final int currentPage;
  final int totalRecords;
  final bool hasMore;
  // Error that happened while loading the *next* page (loadMore). Kept separate
  // from [errorMessage] so a failed page fetch doesn't wipe the loaded list.
  final String? loadMoreError;

  const MyAthletesState({
    this.status = MyAthletesStatus.initial,
    this.athletes = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalRecords = 0,
    this.hasMore = false,
    this.loadMoreError,
  });

  MyAthletesState copyWith({
    MyAthletesStatus? status,
    List<MyAthleteEntity>? athletes,
    String? errorMessage,
    int? currentPage,
    int? totalRecords,
    bool? hasMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) =>
      MyAthletesState(
        status: status ?? this.status,
        athletes: athletes ?? this.athletes,
        errorMessage: errorMessage ?? this.errorMessage,
        currentPage: currentPage ?? this.currentPage,
        totalRecords: totalRecords ?? this.totalRecords,
        hasMore: hasMore ?? this.hasMore,
        loadMoreError:
            clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      );

  @override
  List<Object?> get props => [
        status,
        athletes,
        errorMessage,
        currentPage,
        totalRecords,
        hasMore,
        loadMoreError,
      ];
}
