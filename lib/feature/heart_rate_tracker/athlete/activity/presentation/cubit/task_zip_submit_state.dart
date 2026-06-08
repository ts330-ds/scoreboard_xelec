import 'package:equatable/equatable.dart';

enum TaskZipStatus { idle, fetching, compressing, uploading, polling, complete, error }

class TaskZipSubmitState extends Equatable {
  final TaskZipStatus status;
  final int totalReadings;
  final String message;
  final String? errorMessage;
  final String? jobId;

  const TaskZipSubmitState({
    this.status = TaskZipStatus.idle,
    this.totalReadings = 0,
    this.message = '',
    this.errorMessage,
    this.jobId,
  });

  bool get isWorking =>
      status == TaskZipStatus.fetching ||
      status == TaskZipStatus.compressing ||
      status == TaskZipStatus.uploading ||
      status == TaskZipStatus.polling;

  TaskZipSubmitState copyWith({
    TaskZipStatus? status,
    int? totalReadings,
    String? message,
    String? errorMessage,
    String? jobId,
    bool clearError = false,
  }) {
    return TaskZipSubmitState(
      status: status ?? this.status,
      totalReadings: totalReadings ?? this.totalReadings,
      message: message ?? this.message,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      jobId: jobId ?? this.jobId,
    );
  }

  @override
  List<Object?> get props => [status, totalReadings, message, errorMessage, jobId];
}
