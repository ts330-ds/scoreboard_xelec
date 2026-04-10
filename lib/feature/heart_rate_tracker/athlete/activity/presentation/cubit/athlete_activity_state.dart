import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';

class AthleteActivityState extends Equatable {
  final List<ActivitySession> sessions;       // completed sessions
  final ActivitySession? activeSession;       // currently running session
  final int elapsedSeconds;                   // live timer
  final String selectedActivity;             // user ka selected activity type
  final int selectedDuration;                // minutes
  final String locationText;                 // human readable address
  final bool isLoadingLocation;              // geolocator fetching

  const AthleteActivityState({
    this.sessions = const [],
    this.activeSession,
    this.elapsedSeconds = 0,
    this.selectedActivity = 'Running',
    this.selectedDuration = 30,
    this.locationText = '',
    this.isLoadingLocation = false,
  });

  bool get isSessionActive => activeSession != null;

  int get targetSeconds => selectedDuration * 60;

  // 0.0 to 1.0
  double get progressRatio {
    if (!isSessionActive) return 0;
    final target = activeSession!.targetDurationMinutes * 60;
    if (target == 0) return 0;
    return (elapsedSeconds / target).clamp(0.0, 1.0);
  }

  AthleteActivityState copyWith({
    List<ActivitySession>? sessions,
    ActivitySession? activeSession,
    bool clearActiveSession = false,
    int? elapsedSeconds,
    String? selectedActivity,
    int? selectedDuration,
    String? locationText,
    bool? isLoadingLocation,
  }) {
    return AthleteActivityState(
      sessions: sessions ?? this.sessions,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      selectedActivity: selectedActivity ?? this.selectedActivity,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      locationText: locationText ?? this.locationText,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        activeSession,
        elapsedSeconds,
        selectedActivity,
        selectedDuration,
        locationText,
        isLoadingLocation,
      ];
}
