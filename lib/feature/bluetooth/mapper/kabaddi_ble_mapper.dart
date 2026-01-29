class KabaddiBleMapper {
  /* =======================
   * Team Names
   * ======================= */
  String setTeam1Name(String name) => "KAN1:$name";
  String setTeam2Name(String name) => "KAN2:$name";

  /* =======================
   * Scores
   * ======================= */
  String setTeam1Score(int score) => "KAS1:$score";
  String setTeam2Score(int score) => "KAS2:$score";

  /* =======================
   * Team Colors (RGB565)
   * ======================= */
  String setTeam1Color(int rgb565) =>
      "KAC1:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  String setTeam2Color(int rgb565) =>
      "KAC2:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  /* =======================
   * Quarter
   * ======================= */
  String setQuarter(int quarter) {
    assert(quarter == 1 || quarter == 2);
    return quarter == 1 ? "KAQ1" : "KAQ2";
  }

  /* =======================
   * Match Timer
   * ======================= */
  String setTimerMinutes(int minutes) => "KATN:$minutes";
  String startTimer() => "KATS";
  String pauseTimer() => "KATP";
  String resetTimer() => "KATR";

  /* =======================
   * Raider / Clipart
   * ======================= */
  String showRaiderOnTeam1() => "KAR1";
  String showRaiderOnTeam2() => "KAR2";

  /* =======================
   * Touch
   * Example: KAT1:12 , KAT2:14
   * ======================= */
  String setTeam1Touch(int value) => "KAT1:$value";
  String setTeam2Touch(int value) => "KAT2:$value";

  /* =======================
   * Bonus
   * ======================= */
  String setTeam1Bonus(int value) => "KAB1:$value";
  String setTeam2Bonus(int value) => "KAB2:$value";

  /* =======================
   * All Out
   * ======================= */
  String setTeam1AllOut(int value) => "KAA1:$value";
  String setTeam2AllOut(int value) => "KAA2:$value";

  /* =======================
   * Raid Number
   * ======================= */
  String setRaidNumber(int raid) => "KARD:$raid";

  /* =======================
   * System
   * ======================= */
  String setBrightness(int value) => "KABS:$value";
  String triggerBuzzer() => "KABR";
  String resetScreen() => "KART";
}
