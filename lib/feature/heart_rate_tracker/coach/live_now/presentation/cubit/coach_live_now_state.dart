import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';

enum CoachLiveNowStatus { initial, loading, loadingMore, loaded, error }

class CoachLiveNowState extends Equatable {
  final CoachLiveNowStatus status;
  final List<ActiveTaskEntity> tasks;
  final String? errorMessage;
  final int currentPage;
  final int totalRecords;
  final bool hasMore;
  // Error that happened while loading the *next* page (loadMore). Kept separate
  // from [errorMessage] so a failed page fetch doesn't wipe the loaded list.
  final String? loadMoreError;

  const CoachLiveNowState({
    this.status = CoachLiveNowStatus.initial,
    this.tasks = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalRecords = 0,
    this.hasMore = false,
    this.loadMoreError,
  });

  CoachLiveNowState copyWith({
    CoachLiveNowStatus? status,
    List<ActiveTaskEntity>? tasks,
    String? errorMessage,
    int? currentPage,
    int? totalRecords,
    bool? hasMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return CoachLiveNowState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalRecords: totalRecords ?? this.totalRecords,
      hasMore: hasMore ?? this.hasMore,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        errorMessage,
        currentPage,
        totalRecords,
        hasMore,
        loadMoreError,
      ];
}
