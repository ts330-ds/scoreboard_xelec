class ArcheryBleMapper {
  /* =======================
   * Game Mode
   * ABCD = 4 players
   * ABC = 3 players
   * AB-CD = 2 teams
   * ======================= */
  String setGameMode(String mode) => "ARMD:$mode";

  /* =======================
   * Timer Phase
   * RED, GREEN, YELLOW
   * ======================= */
  String setTimerPhase(String phase) => "ARPH:$phase";

  /* =======================
   * Timer Seconds
   * ======================= */
  String setTimerSeconds(int seconds) => "ARTS:$seconds";

  /* =======================
   * Green Time Setting (60/90/120/180)
   * ======================= */
  String setGreenTime(int seconds) => "ARGT:$seconds";

  /* =======================
   * Current End Number
   * ======================= */
  String setEndNumber(int end) => "AREN:$end";

  /* =======================
   * Total Ends
   * ======================= */
  String setTotalEnds(int total) => "ARTE:$total";

  /* =======================
   * Match Phase (PRACTICE / SCORING / SIGHTER)
   * ======================= */
  String setMatchPhase(String phase) => "ARMP:$phase";

  /* =======================
   * Current Team (for AB-CD mode)
   * AB or CD
   * ======================= */
  String setCurrentTeam(String team) => "ARCT:$team";

  /* =======================
   * Active Players (A, B, C, D)
   * ======================= */
  String setActivePlayers(String players) => "ARAP:$players";

  /* =======================
   * Timer Controls
   * ======================= */
  String startTimer() => "ARSS";
  String pauseTimer() => "ARSP";
  String resetTimer() => "ARSR";

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => "ARBZ";

  /* =======================
   * Brightness (0–255)
   * ======================= */
  String setBrightness(int value) => "ARBS:$value";

  /* =======================
   * Show Idle Screen (Time/Date)
   * ======================= */
  String showIdleScreen() => "ARID";

  /* =======================
   * Show Game Screen
   * ======================= */
  String showGameScreen() => "ARGS";

  /* =======================
   * Full Screen Reset
   * ======================= */
  String resetScreen() => "ARRT";
}
