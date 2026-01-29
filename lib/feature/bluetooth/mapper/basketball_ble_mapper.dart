class BasketBallBleMapper {
  // ======================
  // TEAM NAMES
  // ======================

  String setHomeTeamName(String name) => "BBN1$name";
  String setAwayTeamName(String name) => "BBN2$name";

  // ======================
  // SCORES (DIRECT SET)
  // ======================

  String setHomeScore(int score) {
    assert(score >= 0);
    print("BBS1$score");
    return "BBS1$score";
  }

  String setAwayScore(int score) {
    assert(score >= 0);
    print("BBS2$score");
    return "BBS2$score";
  }

  // ======================
  // QUARTERS (SEPARATE COMMANDS)
  // ======================

  String setQuarter1() => "BBQ1";
  String setQuarter2() => "BBQ2";
  String setQuarter3() => "BBQ3";
  String setQuarter4() => "BBQ4";

  // ======================
  // TEAM COLORS (RGB565 HEX)
  // ======================

  /// Example: "07E0", "F800"
  String setHomeTeamColor(String hex565) => "BBC1$hex565";
  String setAwayTeamColor(String hex565) => "BBC2$hex565";

  // ======================
  // MAIN TIMER
  // ======================

  /// Set timer minutes (seconds auto reset in firmware)
  String setTimerMinutes(int minutes) {
    assert(minutes > 0);
    return "BBTN$minutes";
  }

  String startTimer() => "BBTS";
  String pauseTimer() => "BBTP";
  String resetTimer() => "BBTR";

  // ======================
  // SHOT / MINI TIMER
  // ======================
  String setBrightness(int value) => "HOBS:$value";

  String setBuzzer(int value) => "HOBS:$value";

  String startShotTimer() => "BBMS";
  String resetShotTimer() => "BBMR";

  // ======================
  // SCREEN
  // ======================



  String resetScreen() => "BBRT";
}
