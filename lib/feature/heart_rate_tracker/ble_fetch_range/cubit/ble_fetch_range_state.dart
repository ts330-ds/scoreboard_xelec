import 'package:equatable/equatable.dart';

enum FetchRangeStatus { idle, syncing, complete, error }

class BleFetchRangeState extends Equatable {
  final FetchRangeStatus status;
  final List<Map<dynamic, dynamic>> hrData;
  final List<Map<dynamic, dynamic>> rrData;
  final int hrCount;
  final int rrCount;
  final String message;

  const BleFetchRangeState({
    this.status = FetchRangeStatus.idle,
    this.hrData = const [],
    this.rrData = const [],
    this.hrCount = 0,
    this.rrCount = 0,
    this.message = '',
  });

  bool get isSyncing => status == FetchRangeStatus.syncing;

  BleFetchRangeState copyWith({
    FetchRangeStatus? status,
    List<Map<dynamic, dynamic>>? hrData,
    List<Map<dynamic, dynamic>>? rrData,
    int? hrCount,
    int? rrCount,
    String? message,
  }) {
    return BleFetchRangeState(
      status: status ?? this.status,
      hrData: hrData ?? this.hrData,
      rrData: rrData ?? this.rrData,
      hrCount: hrCount ?? this.hrCount,
      rrCount: rrCount ?? this.rrCount,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, hrData, rrData, hrCount, rrCount, message];
}
