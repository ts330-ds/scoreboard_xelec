class HockeyBleMapper {

  /* =======================
   * Team Names
   * ======================= */
  String setTeam1Name(String name) => "HON1:$name";

  String setTeam2Name(String name) => "HON2:$name";

  /* =======================
   * Scores
   * ======================= */
  String setTeam1Score(int score) => "HOS1:$score";

  String setTeam2Score(int score) => "HOS2:$score";

  /* =======================
   * Quarter
   * ======================= */
  String setQuarter(int quarter) {
    assert(quarter >= 1 && quarter <= 4);
    return "HOQ$quarter";
  }

  /* =======================
   * Timer
   * ======================= */
  String setTimerMinutes(int minutes) => "HOTN:$minutes";

  String startTimer() => "HOTS";

  String pauseTimer() => "HOTP";

  String resetTimer() => "HOTR";

  /* =======================
   * Penalty Corner
   * ======================= */
  String setTeam1PenaltyCorner(int value) => "HOP1:$value";

  String setTeam2PenaltyCorner(int value) => "HOP2:$value";

  /* =======================
   * Shoot Out
   * ======================= */
  String setTeam1ShootOut(int value) => "HOO1:$value";

  String setTeam2ShootOut(int value) => "HOO2:$value";

  /* =======================
   * 7 Meter
   * ======================= */
  String setTeam1SevenMeter(int value) => "HOSM:$value";

  String setTeam2SevenMeter(int value) => "HOSm:$value";

  /* =======================
   * Suspension
   * 1 = Red, 2 = Green
   * ======================= */
  String setTeam1Suspension(int color) {
    assert(color == 1 || color == 2);
    return "HOS1:$color";
  }

  String setTeam2Suspension(int color) {
    assert(color == 1 || color == 2);
    return "HOS2:$color";
  }

  /* =======================
   * Brightness
   * ======================= */
  String setBrightness(int value) => "HOBS:$value";

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer(int value) => "HOBR:$value";

  /* =======================
   * Full Reset
   * ======================= */
  String resetScreen() => "HORT";

  String setBuzzer(bool buzzer) {
    if (buzzer) {
      return "HOBR:${1}";
    } else {
      return "HOBR:${0}";
    }
  }
}