abstract class HeartTrackerPaths {

  // ── Entry ──────────────────────────────────────────────────────────────────
  static const String heartTracker    = '/heart-tracker';
  static const String chooseProfile   = '/choose-profile';

  // ── Athlete Registration ───────────────────────────────────────────────────
  static const String athleteRegistration = '/athlete-registration';

  // ── Athlete Dashboard (ShellRoute tabs) ───────────────────────────────────
  static const String athleteHome         = '/athlete-home';
  static const String athleteActivity     = '/athlete-activity';
  static const String athleteProfile      = '/athlete-profile';
  static const String athleteHistory      = '/athlete-history';
  static const String athleteNotification  = '/athlete-notification';
  static const String athleteTaskDetail    = '/athlete-task-detail';
  static const String athleteTaskResult    = '/athlete-task-result';
  static const String athleteSleepDetail   = '/athlete-sleep-detail';
  static const String athleteHrvDetail     = '/athlete-hrv-detail';

  // ── Coach Auth ────────────────────────────────────────────────────────────
  static const String coachLogin        = '/coach-login';
  static const String coachRegistration = '/coach-registration';

  // ── Coach Request ─────────────────────────────────────────────────────────
  static const String coachAthleteSearch = '/coach-athlete-search';
  static const String coachSendRequest   = '/coach-send-request';

  // ── Coach My Athletes ─────────────────────────────────────────────────────
  static const String coachMyAthletes    = '/coach-my-athletes';
  static const String coachAthleteDetail = '/coach-athlete-detail';

  // ── Coach Live Now ────────────────────────────────────────────────────────
  static const String coachLiveNow = '/coach-live-now';

  // ── Coach Dashboard (ShellRoute tabs) ────────────────────────────────────
  static const String coachHome    = '/coach-home';
  static const String coachProfile = '/coach-profile';

  // ── Demo / Testing ─────────────────────────────────────────────────────────
  static const String bleFetchDemo = '/ble-fetch-demo';

  // ── Shared ─────────────────────────────────────────────────────────────────
  static const String heartBleSelectionScreen = '/heart-ble-selection';

  // ── Legacy (keep for backward compatibility) ───────────────────────────────
  static const String individualProfileRegistration = '/individual-profile-registration';
  static const String indiviMainScreen    = '/indivi-main-screen';
  static const String indiviHomeMobile    = '/indivi-home-mobile';
  static const String indiviActivityMobile = '/indivi-activity-mobile';
  static const String indiviProfileMobile  = '/indivi-profile-mobile';
  static const String indiviHistoryMobile  = '/indivi-history-mobile';
}
