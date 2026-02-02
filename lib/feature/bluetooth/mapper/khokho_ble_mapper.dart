class KhoKhoBleMapper {
  // Team Names
  String setTeam1Name(String name) => "KKN1$name";
  String setTeam2Name(String name) => "KKN2$name";

  // Scores
  String setTeam1Score(int score) => "KKS1$score";
  String setTeam2Score(int score) => "KKS2$score";

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565) =>
      "KKC1${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  String setTeam2Color(int rgb565) =>
      "KKC2${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  // Chase / Defence (1 = Team1 chase, 2 = Team2 chase)
  String setChaseTeam(int team) => "KKCD$team";

  // Inning (1 or 2)
  String setInning(int inning) => "KKIN$inning";

  // Turn (1-4)
  String setTurn(int turn) => "KKTU$turn";

  // Turn Timer
  String setTurnMinutes(int minutes) => "KKTT$minutes";
  String startTurnTimer() => "KKTS";
  String pauseTurnTimer() => "KKTP";
  String resetTurnTimer() => "KKTR";

  // Match Timer
  String setMatchMinutes(int minutes) => "KKMT$minutes";
  String startMatchTimer() => "KKMS";
  String pauseMatchTimer() => "KKMP";
  String resetMatchTimer() => "KKMR";

  // Brightness (0-255)
  String setBrightness(int value) => "KKBS$value";

  // Reset
  String resetScreen() => "KKRT";
}
