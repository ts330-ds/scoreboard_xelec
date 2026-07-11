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

  /// Server pe abhi jo session `in_progress` (ya `active`) hai — usका task.
  /// Non-null hone par athlete ko force kiya jaata hai ki pehle isi ko
  /// finish/stop kare (list + New Task hide ho jaate hain). App-kill ke baad
  /// jab local `isSessionActive` gum ho jaata hai, ye server-side signal us
  /// running session ko wapas surface karta hai.
  final AthleteTaskEntity? inProgressTask;

  const MyTasksState({
    this.status = MyTasksStatus.initial,
    this.tasks = const [],
    this.errorMessage,
    this.isAuthError = false,
    this.currentPage = 1,
    this.totalRecords = 0,
    this.hasMore = false,
    this.inProgressTask,
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
    AthleteTaskEntity? inProgressTask,
    bool clearInProgress = false,
  }) {
    return MyTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthError: clearError ? false : (isAuthError ?? this.isAuthError),
      currentPage: currentPage ?? this.currentPage,
      totalRecords: totalRecords ?? this.totalRecords,
      hasMore: hasMore ?? this.hasMore,
      inProgressTask:
          clearInProgress ? null : (inProgressTask ?? this.inProgressTask),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        errorMessage,
        isAuthError,
        currentPage,
        totalRecords,
        hasMore,
        inProgressTask,
      ];
}
