// Lifecycle events emitted by HeartBleCubit during a history push.
// UI listens to these to show meaningful status messages instead of
// fire-and-forget snackbars.

sealed class PushStatusEvent {
  const PushStatusEvent();
}

/// Push request received; filtering watermarks / building payload.
class PushPreparing extends PushStatusEvent {
  const PushPreparing();
}

/// No logged-in user (anon) — request blocked.
class PushAnonymous extends PushStatusEvent {
  const PushAnonymous();
}

/// Nothing new to send — everything is already under the watermark.
class PushNothingNew extends PushStatusEvent {
  const PushNothingNew();
}

/// Push is already in flight — duplicate request rejected.
class PushAlreadyInFlight extends PushStatusEvent {
  const PushAlreadyInFlight();
}

/// Token / base URL missing — auth not initialised.
class PushMissingAuth extends PushStatusEvent {
  const PushMissingAuth();
}

/// Opening socket connection.
class PushConnecting extends PushStatusEvent {
  const PushConnecting();
}

/// Socket open + monitoring started; batch is being sent.
class PushUploading extends PushStatusEvent {
  final int hrCount;
  final int rrCount;
  final int sleepCount;
  const PushUploading({
    required this.hrCount,
    required this.rrCount,
    required this.sleepCount,
  });

  int get total => hrCount + rrCount + sleepCount;
}

/// Backend acknowledged the batch — watermarks committed.
class PushSucceeded extends PushStatusEvent {
  final Map<String, dynamic> ack;
  const PushSucceeded(this.ack);
}

/// Socket reported a server-side error.
class PushFailed extends PushStatusEvent {
  final String message;
  const PushFailed(this.message);
}

/// Auth rejected by server.
class PushAuthFailed extends PushStatusEvent {
  final String message;
  const PushAuthFailed(this.message);
}

/// 20s passed without ack — gave up.
class PushTimedOut extends PushStatusEvent {
  const PushTimedOut();
}

/// Socket dropped mid-flow before ack.
class PushDisconnected extends PushStatusEvent {
  const PushDisconnected();
}

/// Local error before the socket flow started (build/network exception).
class PushBuildFailed extends PushStatusEvent {
  final String message;
  const PushBuildFailed(this.message);
}

/// Push attempted within the cooldown window (1h). [minutesRemaining] tells
/// the UI when the next push can fire.
class PushCooldownActive extends PushStatusEvent {
  final int minutesRemaining;
  const PushCooldownActive(this.minutesRemaining);
}

/// Device not connected — sync required before push.
class PushNotConnected extends PushStatusEvent {
  const PushNotConnected();
}

/// V3: Server accepted the batch — polling job status.
class PushPolling extends PushStatusEvent {
  final String jobId;
  const PushPolling(this.jobId);
}
