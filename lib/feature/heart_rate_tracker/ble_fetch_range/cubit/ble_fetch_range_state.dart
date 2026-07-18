import 'package:equatable/equatable.dart';

enum FetchRangeStatus { idle, syncing, complete, error }

class BleFetchRangeState extends Equatable {
  final FetchRangeStatus status;
  final List<Map<dynamic, dynamic>> hrData;
  final List<Map<dynamic, dynamic>> rrData;
  final int hrCount;
  final int rrCount;
  final String message;

  /// Newest history record ka start-stamp (UTC seconds me normalized).
  /// Close-aware re-fetch iska istemaal karta hai: agar ye session ke end se
  /// aage hai, to session ka record commit ho chuka (band ne naya record khol
  /// diya) — retry se aur data nahi aayega. 0 = koi record info nahi.
  /// (Sirf task-upload padhta hai; baaki consumers ise ignore karte hain.)
  final int recordMaxStampSec;

  const BleFetchRangeState({
    this.status = FetchRangeStatus.idle,
    this.hrData = const [],
    this.rrData = const [],
    this.hrCount = 0,
    this.rrCount = 0,
    this.message = '',
    this.recordMaxStampSec = 0,
  });

  bool get isSyncing => status == FetchRangeStatus.syncing;

  BleFetchRangeState copyWith({
    FetchRangeStatus? status,
    List<Map<dynamic, dynamic>>? hrData,
    List<Map<dynamic, dynamic>>? rrData,
    int? hrCount,
    int? rrCount,
    String? message,
    int? recordMaxStampSec,
  }) {
    return BleFetchRangeState(
      status: status ?? this.status,
      hrData: hrData ?? this.hrData,
      rrData: rrData ?? this.rrData,
      hrCount: hrCount ?? this.hrCount,
      rrCount: rrCount ?? this.rrCount,
      message: message ?? this.message,
      recordMaxStampSec: recordMaxStampSec ?? this.recordMaxStampSec,
    );
  }

  @override
  List<Object?> get props =>
      [status, hrData, rrData, hrCount, rrCount, message, recordMaxStampSec];
}
