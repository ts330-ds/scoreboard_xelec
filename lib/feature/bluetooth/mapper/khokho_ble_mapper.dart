class KhoKhoBleMapper {

  /* =======================
   * Team Names
   * ======================= */
  String setTeam1Name(String name) => "KKN1:$name";
  String setTeam2Name(String name) => "KKN2:$name";

  /* =======================
   * Scores
   * ======================= */
  String setTeam1Score(int score) => "KKS1:$score";
  String setTeam2Score(int score) => "KKS2:$score";

  /* =======================
   * Team Colors (RGB565)
   * ======================= */
  String setTeam1Color(int rgb565) =>
      "KKC1:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  String setTeam2Color(int rgb565) =>
      "KKC2:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  /* =======================
   * Chase / Defence
   * 1 = Team1 chase
   * 2 = Team2 chase
   * ======================= */
  String setChaseTeam(int team) {
    assert(team == 1 || team == 2);
    return "KKCD:$team";
  }

  /* =======================
   * Inning
   * 1 -> "1/2"
   * 2 -> "2/2"
   * ======================= */
  String setInning(int inning) {
    assert(inning == 1 || inning == 2);
    return "KKIN:$inning";
  }

  /* =======================
   * Turn (1–4)
   * ======================= */
  String setTurn(int turn) {
    assert(turn >= 1 && turn <= 4);
    return "KKTU:$turn";
  }

  /* =======================
   * Turn Timer
   * ======================= */
  String setTurnMinutes(int minutes) => "KKTT:$minutes";
  String startTurnTimer() => "KKTS";
  String pauseTurnTimer() => "KKTP";
  String resetTurnTimer() => "KKTR";

  /* =======================
   * Match Timer
   * ======================= */
  String setMatchMinutes(int minutes) => "KKMT:$minutes";
  String startMatchTimer() => "KKMS";
  String pauseMatchTimer() => "KKMP";
  String resetMatchTimer() => "KKMR";

  /* =======================
   * Brightness (0–255)
   * ======================= */
  String setBrightness(int value) => "KKBS:$value";

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => "KKBR";

  /* =======================
   * Full Screen Reset
   * ======================= */
  String resetScreen() => "KKRT";
}
