class HockeyBleMapper {
  // ======================
  // TEAM NAMES
  // ======================

  /// Team 1 name (Home)
  String setHomeTeamName(String name) => "HON1${_safeName(name)}";

  /// Team 2 name (Away)
  String setAwayTeamName(String name) => "HON2${_safeName(name)}";

  // ======================
  // SCORES (INCREMENT)
  // ======================

  /// Increment Team 1 score
  String incrementHomeScore() => "HOS1";

  /// Increment Team 2 score
  String incrementAwayScore() => "HOS2";

  // ======================
  // QUARTERS
  // ======================

  String setQuarter(int quarter) {
    assert(quarter >= 1 && quarter <= 4);
    return "HOQ$quarter";
  }

  // ======================
  // MAIN TIMER
  // ======================

  /// Set timer number (minutes or value as per firmware)
  String setTimerNumber(int value) {
    assert(value > 0);
    return "HOTN$value";
  }

  String startTimer() => "HOTS";
  String pauseTimer() => "HOTP";
  String resetTimer() => "HOTR";

  // ======================
  // PENALTY CORNER
  // ======================

  /// Penalty corner for Team 1
  String setPenaltyCornerTeam1(int value) {
    assert(value >= 0);
    return "HOP1$value";
  }

  /// Penalty corner for Team 2
  String setPenaltyCornerTeam2(int value) {
    assert(value >= 0);
    return "HOP2$value";
  }

  // ======================
  // SHOOT OUT
  // ======================

  /// Shoot-out score for Team 1
  String setShootOutTeam1(int value) {
    assert(value >= 0);
    return "HOO1$value";
  }

  /// Shoot-out score for Team 2
  String setShootOutTeam2(int value) {
    assert(value >= 0);
    return "HOO2$value";
  }

  // ======================
  // 7M (PENALTY STROKE)
  // ======================

  /// Team 1 – 7 meter value
  String setTeam1SevenMeter(int value) {
    assert(value >= 0);
    return "HOSM$value";
  }

  /// Team 2 – 7 meter value
  String setTeam2SevenMeter(int value) {
    assert(value >= 0);
    return "HOSm$value"; // ⚠️ lowercase 'm' as per protocol
  }

  // ======================
  // SUSPENSION
  // ======================

  /// Team 1 suspension
  /// 1 = Red, 2 = Green
  String setTeam1Suspension(int type) {
    assert(type == 1 || type == 2);
    return "HOS1$type";
  }

  /// Team 2 suspension
  /// 1 = Red, 2 = Green
  String setTeam2Suspension(int type) {
    assert(type == 1 || type == 2);
    return "HOS2$type";
  }

  // ======================
  // SCREEN & SYSTEM
  // ======================

  String resetScreen() => "HORT";

  String setBrightness(int value) {
    assert(value >= 0 && value <= 100);
    return "HOBS$value";
  }

  String buzzer() => "HOBR";

  // ======================
  // HELPERS
  // ======================

  String _safeName(String name) =>
      name.substring(0, name.length.clamp(0, 10));
}
