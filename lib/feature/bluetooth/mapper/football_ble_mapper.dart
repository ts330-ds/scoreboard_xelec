class FootballBleMapper {

  /* =======================
   * Team Names
   * ======================= */
  String setTeam1Name(String name) => "FON1:$name";
  String setTeam2Name(String name) => "FON2:$name";

  /* =======================
   * Scores
   * ======================= */
  String setTeam1Score(int score) => "FOS1:$score";
  String setTeam2Score(int score) => "FOS2:$score";

  /* =======================
   * Team Name Colors (RGB565)
   * ======================= */
  String setTeam1Color(int rgb565) =>
      "FOC1:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  String setTeam2Color(int rgb565) =>
      "FOC2:0x${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  /* =======================
   * Period / Half
   * ======================= */
  String setFirstHalf() => "FOQ1";
  String setSecondHalf() => "FOQ2";

  /* =======================
   * Extra Time Text
   * Example: +2'
   * ======================= */
  String setExtraTime(String text) => "FOET:$text";

  /* =======================
   * Timer
   * ======================= */
  String setTimerMinutes(int minutes) => "FOTN:$minutes";
  String startTimer() => "FOTS";
  String pauseTimer() => "FOTP";
  String resetTimer() => "FOTR";

  /* =======================
   * Brightness (0–255)
   * ======================= */
  String setBrightness(int value) => "FOBS:$value";

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => "FOBR";

  /* =======================
   * Full Screen Reset
   * ======================= */
  String resetScreen() => "FORT";
}
