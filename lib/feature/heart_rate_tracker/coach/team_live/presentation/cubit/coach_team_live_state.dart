import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';
import 'package:xelex_esp/service/socket/team_live_socket_service.dart';

enum CoachTeamLiveStatus { connecting, reconnecting, watching, error }

/// Grid me ek athlete ka card (task_id se keyed — har live event me task_id aata hai).
class TeamAthleteCard extends Equatable {
  final int taskId;
  final int athleteId;
  final String athleteName;
  final String taskName;
  final int heartRate; // 0 = abhi koi reading nahi aayi
  final double? spo2;
  final double? sugarLevel;
  final int? stressLevel;
  final double? lat;
  final double? lng;
  // null = abhi tak reading nahi (sirf seed hua hai active-tasks list se).
  final DateTime? lastUpdate;
  // Card kab seed hua (active-tasks list se). Agar iske baad stale-threshold
  // tak koi reading na aaye to card offline maano — is se woh case handle hota
  // hai jab athlete app kill kar de par backend task ko abhi in_progress dikhata
  // rahe (coach re-enter kare to card seed to hota hai par kabhi live nahi hota).
  final DateTime seededAt;
  // Connection drop ya stale fallback se card grey ho jaata hai.
  final bool isOffline;

  TeamAthleteCard({
    required this.taskId,
    required this.athleteId,
    required this.athleteName,
    required this.taskName,
    this.heartRate = 0,
    this.spo2,
    this.sugarLevel,
    this.stressLevel,
    this.lat,
    this.lng,
    this.lastUpdate,
    DateTime? seededAt,
    this.isOffline = false,
  }) : seededAt = seededAt ?? DateTime.now();

  bool get hasReading => lastUpdate != null && heartRate > 0;

  /// Active-tasks list se card seed karo (abhi koi live reading nahi).
  factory TeamAthleteCard.seed(ActiveTaskEntity t) => TeamAthleteCard(
        taskId: t.taskId,
        athleteId: t.athleteId,
        athleteName: t.athleteName,
        taskName: t.taskName,
      );

  /// Naya live_result_update aaya — vitals update karo, online maano.
  TeamAthleteCard applyReading(TeamTaskReading r) => TeamAthleteCard(
        taskId: taskId,
        athleteId: athleteId,
        athleteName: athleteName,
        taskName: taskName,
        heartRate: r.heartRate,
        spo2: r.spo2,
        sugarLevel: r.sugarLevel,
        stressLevel: r.stressLevel,
        lat: r.lat,
        lng: r.lng,
        lastUpdate: r.timestamp,
        seededAt: seededAt,
        isOffline: false,
      );

  TeamAthleteCard copyWith({bool? isOffline}) => TeamAthleteCard(
        taskId: taskId,
        athleteId: athleteId,
        athleteName: athleteName,
        taskName: taskName,
        heartRate: heartRate,
        spo2: spo2,
        sugarLevel: sugarLevel,
        stressLevel: stressLevel,
        lat: lat,
        lng: lng,
        lastUpdate: lastUpdate,
        seededAt: seededAt,
        isOffline: isOffline ?? this.isOffline,
      );

  @override
  List<Object?> get props => [
        taskId,
        athleteId,
        athleteName,
        taskName,
        heartRate,
        spo2,
        sugarLevel,
        stressLevel,
        lat,
        lng,
        lastUpdate,
        isOffline,
      ];
}

class CoachTeamLiveState extends Equatable {
  final CoachTeamLiveStatus status;
  // task_id → card.
  final Map<int, TeamAthleteCard> cards;
  final String? errorMessage;
  final int reconnectAttempt;
  final bool isReconnectExhausted;
  final bool isAuthFailure;

  const CoachTeamLiveState({
    this.status = CoachTeamLiveStatus.connecting,
    this.cards = const {},
    this.errorMessage,
    this.reconnectAttempt = 0,
    this.isReconnectExhausted = false,
    this.isAuthFailure = false,
  });

  /// athleteName se sorted — grid order stable rahe.
  List<TeamAthleteCard> get sortedCards {
    final list = cards.values.toList()
      ..sort((a, b) => a.athleteName.toLowerCase().compareTo(
            b.athleteName.toLowerCase(),
          ));
    return list;
  }

  CoachTeamLiveState copyWith({
    CoachTeamLiveStatus? status,
    Map<int, TeamAthleteCard>? cards,
    String? errorMessage,
    int? reconnectAttempt,
    bool? isReconnectExhausted,
    bool? isAuthFailure,
  }) {
    return CoachTeamLiveState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      isReconnectExhausted: isReconnectExhausted ?? this.isReconnectExhausted,
      isAuthFailure: isAuthFailure ?? this.isAuthFailure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cards,
        errorMessage,
        reconnectAttempt,
        isReconnectExhausted,
        isAuthFailure,
      ];
}
