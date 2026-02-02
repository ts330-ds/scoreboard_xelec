class KabaddiBleMapper {
  // Team Names
  String setTeam1Name(String name) => "KAN1$name";
  String setTeam2Name(String name) => "KAN2$name";

  // Scores
  String setTeam1Score(int score) => "KAS1$score";
  String setTeam2Score(int score) => "KAS2$score";

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565) =>
      "KAC1${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  String setTeam2Color(int rgb565) =>
      "KAC2${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  // Quarter (1 or 2)
  String setQuarter(int quarter) => quarter == 1 ? "KAQ1" : "KAQ2";

  // Timer
  String setTimerMinutes(int minutes) => "KATN$minutes";
  String startTimer() => "KATS";
  String pauseTimer() => "KATP";
  String resetTimer() => "KATR";

  // Raider Icon
  String showRaiderOnTeam1() => "KAR1";
  String showRaiderOnTeam2() => "KAR2";
  String hideRaider() => "KAR0";

  // Touch
  String setTeam1Touch(int value) => "KAT1$value";
  String setTeam2Touch(int value) => "KAT2$value";

  // Bonus
  String setTeam1Bonus(int value) => "KAB1$value";
  String setTeam2Bonus(int value) => "KAB2$value";

  // All Out
  String setTeam1AllOut(int value) => "KAA1$value";
  String setTeam2AllOut(int value) => "KAA2$value";

  // Raid Number
  String setRaidNumber(int raid) => "KARD$raid";

  // Brightness (0-255)
  String setBrightness(int value) => "KABS$value";

  // Reset
  String resetScreen() => "KART";
}
