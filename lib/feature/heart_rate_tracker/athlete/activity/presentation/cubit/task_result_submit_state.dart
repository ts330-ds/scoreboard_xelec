import 'package:equatable/equatable.dart';

enum TaskSubmitStatus { idle, fetching, uploading, complete, error }

class TaskResultSubmitState extends Equatable {
  final TaskSubmitStatus status;
  final int totalReadings;
  final int totalChunks;
  final int currentChunk;
  final int uploadedReadings;
  final String message;
  final String? errorMessage;

  const TaskResultSubmitState({
    this.status = TaskSubmitStatus.idle,
    this.totalReadings = 0,
    this.totalChunks = 0,
    this.currentChunk = 0,
    this.uploadedReadings = 0,
    this.message = '',
    this.errorMessage,
  });

  bool get isWorking =>
      status == TaskSubmitStatus.fetching ||
      status == TaskSubmitStatus.uploading;

  double get progress =>
      totalChunks > 0 ? currentChunk / totalChunks : 0.0;

  TaskResultSubmitState copyWith({
    TaskSubmitStatus? status,
    int? totalReadings,
    int? totalChunks,
    int? currentChunk,
    int? uploadedReadings,
    String? message,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskResultSubmitState(
      status: status ?? this.status,
      totalReadings: totalReadings ?? this.totalReadings,
      totalChunks: totalChunks ?? this.totalChunks,
      currentChunk: currentChunk ?? this.currentChunk,
      uploadedReadings: uploadedReadings ?? this.uploadedReadings,
      message: message ?? this.message,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        totalReadings,
        totalChunks,
        currentChunk,
        uploadedReadings,
        message,
        errorMessage,
      ];
}
