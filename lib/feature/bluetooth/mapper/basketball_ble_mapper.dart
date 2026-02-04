import 'package:flutter/foundation.dart';

class BasketBallBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🏀 BLE Command: $command');
    return command;
  }

  // ======================
  // TEAM NAMES
  // ======================

  String setHomeTeamName(String name) => _log("BBN1$name");
  String setAwayTeamName(String name) => _log("BBN2$name");

  // ======================
  // SCORES (DIRECT SET)
  // ======================

  String setHomeScore(int score) {
    assert(score >= 0);
    return _log("BBS1$score");
  }

  String setAwayScore(int score) {
    assert(score >= 0);
    return _log("BBS2$score");
  }

  // ======================
  // QUARTERS (SEPARATE COMMANDS)
  // ======================

  String setQuarter1() => _log("BBQ1");
  String setQuarter2() => _log("BBQ2");
  String setQuarter3() => _log("BBQ3");
  String setQuarter4() => _log("BBQ4");

  // ======================
  // TEAM COLORS (RGB565 HEX)
  // ======================

  /// Example: "07E0", "F800"
  String setHomeTeamColor(String hex565) => _log("BBC1$hex565");
  String setAwayTeamColor(String hex565) => _log("BBC2$hex565");

  // ======================
  // MAIN TIMER
  // ======================

  /// Set timer minutes (seconds auto reset in firmware)
  String setTimerMinutes(int minutes) {
    assert(minutes > 0);
    return _log("BBTN$minutes");
  }

  String startTimer() => _log("BBTS");
  String pauseTimer() => _log("BBTP");
  String resetTimer() => _log("BBTR");

  // ======================
  // SHOT / MINI TIMER
  // ======================

  String setBrightness(int value) => _log("HOBS:$value");
  String setBuzzer(int value) => _log("HOBS:$value");

  String startShotTimer() => _log("BBMS");
  String resetShotTimer() => _log("BBMR");

  // ======================
  // SCREEN
  // ======================

  String resetScreen() => _log("BBRT");
}
