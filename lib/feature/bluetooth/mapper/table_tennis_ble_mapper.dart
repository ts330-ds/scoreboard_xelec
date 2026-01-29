class TableTennisBleMapper {

  /* =======================
   * Team Names
   * ======================= */
  String setTeam1Name(String name) => "TTN1:$name";
  String setTeam2Name(String name) => "TTN2:$name";

  /* =======================
   * Scores
   * ======================= */
  String setTeam1Score(int score) => "TTS1:$score";
  String setTeam2Score(int score) => "TTS2:$score";

  /* =======================
   * Team Background Colors (RGB565 HEX)
   * ======================= */
  String setTeam1Color(int rgb565Hex) {
    final command =
        "TTC1:${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}";

    print("[BLE] Send Team1 Color -> $command");

    return command;
  }

  String setTeam2Color(int rgb565Hex) =>
      "TTC2:${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}}";

  /* =======================
   * Won Circles
   * ======================= */

  /// Team 1 won set (1–4)
  String setTeam1Won(int count) {
    assert(count >= 1 && count <= 4);
    return "TTW$count";
  }

  /// Team 2 won set (1–4)
  /// ⚠ lowercase 'w' is REQUIRED
  String setTeam2Won(int count) {
    assert(count >= 1 && count <= 4);
    return "TTw$count";
  }

  /* =======================
   * Timeout / Suspension
   * 1 = Blue, 2 = Green
   * ======================= */
  String setTeam1Timeout(int value) {
    assert(value == 1 || value == 2);
    return "TTO1:$value";
  }

  String setTeam2Timeout(int value) {
    assert(value == 1 || value == 2);
    return "TTO2:$value";
  }

  /* =======================
   * Timer
   * ======================= */
  String setTimerMinutes(int minutes) => "TTTN:$minutes";
  String startTimer() => "TTTS";
  String pauseTimer() => "TTTP";
  String resetTimer() => "TTTR";

  /* =======================
   * Serve Indicator
   * 1 = Team1, 2 = Team2
   * ======================= */
  String setServe(int team) {
    assert(team == 1 || team == 2);
    return "TTSV:$team";
  }

  /* =======================
   * Match Number (1–7)
   * ======================= */
  String setMatch(int match) {
    assert(match >= 1 && match <= 7);
    return "TTMH:$match";
  }

  /* =======================
   * Brightness (0–255)
   * ======================= */
  String setBrightness(int value) => "TTBS:$value";

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => "TTBR";

  /* =======================
   * Full Screen Reset
   * ======================= */
  String resetScreen() => "TTRT";
}
