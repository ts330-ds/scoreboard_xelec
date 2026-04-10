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
  static const String athleteNotification = '/athlete-notification';

  // ── Coach Registration ─────────────────────────────────────────────────────
  static const String coachRegistration = '/coach-registration';

  // ── Coach Dashboard ────────────────────────────────────────────────────────
  static const String coachHome = '/coach-home';

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
