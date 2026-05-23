import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';

class AthleteActivityState extends Equatable {
  final List<ActivitySession> sessions;
  final ActivitySession? activeSession;
  final int elapsedSeconds;
  final String selectedActivity;
  final int selectedDuration;
  final String locationText;
  final bool isLoadingLocation;

  // Task creation
  final String taskName;
  final bool isCreatingTask;
  final String? taskError;

  // Task created but session not started yet
  final int? pendingTaskId;

  // Active task (API se mila hua id)
  final int? activeTaskId;

  // Just-completed task — set when session ends so UI can pop the
  // feedback (RPE + notes) sheet. UI clears it via [acknowledgeFeedbackPrompt]
  // after handling, so the sheet doesn't reopen.
  final int? pendingFeedbackTaskId;

  // Socket
  final bool isStoppingSession;
  final bool isSocketConnected;
  final bool isSocketReconnecting;
  final String? socketError;
  // Current reconnect attempt # (UI me "Reconnecting (3)…" dikhane ke liye).
  final int reconnectAttempt;
  // Budget khatm — automatic retry band, user "Retry" dabaye.
  final bool isReconnectExhausted;
  // Auth fail (token expired/invalid) — user ko re-login pe bhejna hai.
  final bool isAuthFailure;

  // Biometrics (device/sensor se aate hain — heart_rate ke alawa sab optional)
  final double? sugarLevel;
  final double? spo2;
  final double? lat;
  final double? lng;
  final int? stressLevel;
  final double? hrv;

  const AthleteActivityState({
    this.sessions = const [],
    this.activeSession,
    this.elapsedSeconds = 0,
    this.selectedActivity = 'Running',
    this.selectedDuration = 0,
    this.locationText = '',
    this.isLoadingLocation = false,
    this.taskName = '',
    this.isCreatingTask = false,
    this.taskError,
    this.pendingTaskId,
    this.activeTaskId,
    this.pendingFeedbackTaskId,
    this.isStoppingSession = false,
    this.isSocketConnected = false,
    this.isSocketReconnecting = false,
    this.socketError,
    this.reconnectAttempt = 0,
    this.isReconnectExhausted = false,
    this.isAuthFailure = false,
    this.sugarLevel,
    this.spo2,
    this.lat,
    this.lng,
    this.stressLevel,
    this.hrv,
  });

  bool get hasPendingTask => pendingTaskId != null && activeSession == null;
  bool get isSessionActive => activeSession != null;

  int get targetSeconds => selectedDuration * 60;

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
    String? taskName,
    bool? isCreatingTask,
    String? taskError,
    bool clearTaskError = false,
    int? pendingTaskId,
    bool clearPendingTaskId = false,
    int? activeTaskId,
    bool clearActiveTaskId = false,
    int? pendingFeedbackTaskId,
    bool clearPendingFeedbackTaskId = false,
    bool? isStoppingSession,
    bool? isSocketConnected,
    bool? isSocketReconnecting,
    String? socketError,
    bool clearSocketError = false,
    int? reconnectAttempt,
    bool? isReconnectExhausted,
    bool? isAuthFailure,
    double? sugarLevel,
    double? spo2,
    double? lat,
    double? lng,
    int? stressLevel,
    double? hrv,
  }) {
    return AthleteActivityState(
      sessions: sessions ?? this.sessions,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      selectedActivity: selectedActivity ?? this.selectedActivity,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      locationText: locationText ?? this.locationText,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      taskName: taskName ?? this.taskName,
      isCreatingTask: isCreatingTask ?? this.isCreatingTask,
      taskError: clearTaskError ? null : (taskError ?? this.taskError),
      pendingTaskId: clearPendingTaskId ? null : (pendingTaskId ?? this.pendingTaskId),
      activeTaskId: clearActiveTaskId ? null : (activeTaskId ?? this.activeTaskId),
      pendingFeedbackTaskId: clearPendingFeedbackTaskId
          ? null
          : (pendingFeedbackTaskId ?? this.pendingFeedbackTaskId),
      isStoppingSession: isStoppingSession ?? this.isStoppingSession,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      isSocketReconnecting: isSocketReconnecting ?? this.isSocketReconnecting,
      socketError: clearSocketError ? null : (socketError ?? this.socketError),
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      isReconnectExhausted: isReconnectExhausted ?? this.isReconnectExhausted,
      isAuthFailure: isAuthFailure ?? this.isAuthFailure,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      spo2: spo2 ?? this.spo2,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      stressLevel: stressLevel ?? this.stressLevel,
      hrv: hrv ?? this.hrv,
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
        taskName,
        isCreatingTask,
        taskError,
        pendingTaskId,
        activeTaskId,
        pendingFeedbackTaskId,
        isStoppingSession,
        isSocketConnected,
        isSocketReconnecting,
        socketError,
        reconnectAttempt,
        isReconnectExhausted,
        isAuthFailure,
        sugarLevel,
        spo2,
        lat,
        lng,
        stressLevel,
        hrv,
      ];
}
