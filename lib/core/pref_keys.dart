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
}
