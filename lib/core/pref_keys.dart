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

  // Sports cache
  static const String sportsData = 'sports_data';
  static const String sportsTimestamp = 'sports_timestamp';
}
