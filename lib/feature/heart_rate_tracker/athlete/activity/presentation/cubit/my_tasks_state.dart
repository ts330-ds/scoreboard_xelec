import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';

enum MyTasksStatus { initial, loading, loadingMore, loaded, error }

class MyTasksState extends Equatable {
  final MyTasksStatus status;
  final List<AthleteTaskEntity> tasks;
  final String? errorMessage;
  final bool isAuthError;
  final int currentPage;
  final int totalRecords;
  final bool hasMore;

  const MyTasksState({
    this.status = MyTasksStatus.initial,
    this.tasks = const [],
    this.errorMessage,
    this.isAuthError = false,
    this.currentPage = 1,
    this.totalRecords = 0,
    this.hasMore = false,
  });

  MyTasksState copyWith({
    MyTasksStatus? status,
    List<AthleteTaskEntity>? tasks,
    String? errorMessage,
    bool clearError = false,
    bool? isAuthError,
    int? currentPage,
    int? totalRecords,
    bool? hasMore,
  }) {
    return MyTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthError: clearError ? false : (isAuthError ?? this.isAuthError),
      currentPage: currentPage ?? this.currentPage,
      totalRecords: totalRecords ?? this.totalRecords,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props =>
      [status, tasks, errorMessage, isAuthError, currentPage, totalRecords, hasMore];
}
