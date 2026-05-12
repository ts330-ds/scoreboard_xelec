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
  // Athlete temporarily offline — UI me banner dikhao, dialog NAHI.
  final bool isAthleteConnectionLost;
  // Coach apne socket pe reconnect kar raha hai — attempt count for banner.
  final int reconnectAttempt;
  // Budget khatm — automatic retry band, user "Retry" dabaye.
  final bool isReconnectExhausted;
  // Auth fail — coach ko re-login pe bhejna padega.
  final bool isAuthFailure;

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
    this.isAthleteConnectionLost = false,
    this.reconnectAttempt = 0,
    this.isReconnectExhausted = false,
    this.isAuthFailure = false,
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
    bool? isAthleteConnectionLost,
    int? reconnectAttempt,
    bool? isReconnectExhausted,
    bool? isAuthFailure,
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
      isAthleteConnectionLost: isAthleteConnectionLost ?? this.isAthleteConnectionLost,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      isReconnectExhausted: isReconnectExhausted ?? this.isReconnectExhausted,
      isAuthFailure: isAuthFailure ?? this.isAuthFailure,
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
        isAthleteConnectionLost,
        reconnectAttempt,
        isReconnectExhausted,
        isAuthFailure,
      ];
}
