abstract class PrefKeys {
  PrefKeys._();

  // Auth User
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String validEmail = 'valid_email';
  static const String userRole = 'user_role';

  // Profile
  static const String userAge = 'user_age';
  static const String userWeight = 'user_weight';
  static const String userHeight = 'user_height';
  static const String userPhone = 'user_phone';
  static const String userGender = 'user_gender';

  // Coach Auth
  static const String coachToken = 'coach_token';
  static const String coachId = 'coach_id';
  static const String coachName = 'coach_name';
  static const String coachEmail = 'coach_email';
  static const String coachRole = 'coach_role';

  // Feature Selection
  static const String selectedFeature = 'selected_feature';

  // Onboarding flags
  static const String batteryOptPromptShown = 'battery_opt_prompt_shown';

  // History push watermarks (per athlete: '<prefix><athleteId>')
  // Backend has no dedupe — these prevent re-emitting already-sent records.
  static const String lastEmittedHrStampPrefix = 'last_emitted_hr_stamp_';
  static const String lastEmittedRrStampPrefix = 'last_emitted_rr_stamp_';
  static const String lastEmittedSleepUtcPrefix = 'last_emitted_sleep_utc_';

  // Last completed BLE history sync — used by 2h cooldown gate
  // (force=true bypasses; manual sync button uses force).
  static const String lastHistorySyncAtPrefix = 'last_history_sync_at_';

  // Last successful server push — used by 1h cooldown gate so we don't
  // spam the server on every sync. force=true bypasses.
  static const String lastHistoryPushAtPrefix = 'last_history_push_at_';

  // Server is the single source of truth for "last synced". These mirror the
  // /last_timestamp API response into local so the UI can render without a
  // network call. Updated only via the single choke-point (refreshServerWatermark).
  //   serverLastStamp = newest reading timestamp the server has (epoch millis)
  //   serverCheckedAt = wall-clock of last successful server reach (epoch millis)
  static const String serverLastStampPrefix = 'server_last_stamp_ms_';
  static const String serverCheckedAtPrefix = 'server_checked_at_ms_';

  // V3 job polling state — persisted so polling can resume after app kill
  static const String pollingActive = 'v3_polling_active';
  static const String pollingJobId = 'v3_polling_job_id';
  static const String pollingStartedAt = 'v3_polling_started_at';

  // Active activity session — disk pe persist hoti hai taaki process death
  // (phone off / app swipe-kill) ke baad app dobara khulne par recover ho sake.
  // startSession pe set, _endSession pe clear. Launch pe attemptSessionRecovery()
  // inhe padh ke server status verify karta hai (resume / upload / discard).
  static const String activeSessionTaskId = 'active_session_task_id';
  static const String activeSessionStartMs = 'active_session_start_ms';
  static const String activeSessionTargetMin = 'active_session_target_min';
  static const String activeSessionActivity = 'active_session_activity';
  static const String activeSessionLocation = 'active_session_location';
}
