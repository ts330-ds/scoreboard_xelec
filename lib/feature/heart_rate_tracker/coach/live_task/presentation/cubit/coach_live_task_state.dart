import 'package:equatable/equatable.dart';
import 'package:xelex_esp/service/socket/coach_live_task_socket_service.dart';

enum CoachLiveTaskStatus { connecting, reconnecting, watching, athleteStopped, error }

class CoachLiveTaskState extends Equatable {
  final CoachLiveTaskStatus status;
  final List<CoachLiveReading> readings; // live reading history
  final int totalReadings;               // server se aaya count
  final int latestBpm;
  final double? latestSugarLevel;
  final double? latestSpo2;
  final double? latestLat;
  final double? latestLng;
  final int? latestStressLevel;
  final String? errorMessage;
  final bool isAthleteStopped;

  const CoachLiveTaskState({
    this.status = CoachLiveTaskStatus.connecting,
    this.readings = const [],
    this.totalReadings = 0,
    this.latestBpm = 0,
    this.latestSugarLevel,
    this.latestSpo2,
    this.latestLat,
    this.latestLng,
    this.latestStressLevel,
    this.errorMessage,
    this.isAthleteStopped = false,
  });

  CoachLiveTaskState copyWith({
    CoachLiveTaskStatus? status,
    List<CoachLiveReading>? readings,
    int? totalReadings,
    int? latestBpm,
    double? latestSugarLevel,
    double? latestSpo2,
    double? latestLat,
    double? latestLng,
    int? latestStressLevel,
    String? errorMessage,
    bool? isAthleteStopped,
  }) {
    return CoachLiveTaskState(
      status: status ?? this.status,
      readings: readings ?? this.readings,
      totalReadings: totalReadings ?? this.totalReadings,
      latestBpm: latestBpm ?? this.latestBpm,
      latestSugarLevel: latestSugarLevel ?? this.latestSugarLevel,
      latestSpo2: latestSpo2 ?? this.latestSpo2,
      latestLat: latestLat ?? this.latestLat,
      latestLng: latestLng ?? this.latestLng,
      latestStressLevel: latestStressLevel ?? this.latestStressLevel,
      errorMessage: errorMessage ?? this.errorMessage,
      isAthleteStopped: isAthleteStopped ?? this.isAthleteStopped,
    );
  }

  @override
  List<Object?> get props => [
        status,
        readings,
        totalReadings,
        latestBpm,
        latestSugarLevel,
        latestSpo2,
        latestLat,
        latestLng,
        latestStressLevel,
        errorMessage,
        isAthleteStopped,
      ];
}
