class TableTennisBleMapper {
  // Team Names
  String setTeam1Name(String name) => "TTN1$name";
  String setTeam2Name(String name) => "TTN2$name";

  // Scores
  String setTeam1Score(int score) => "TTS1$score";
  String setTeam2Score(int score) => "TTS2$score";

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565Hex) =>
      "TTC1${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}";
  String setTeam2Color(int rgb565Hex) =>
      "TTC2${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}";

  // Won (1-4)
  String setTeam1Won(int count) => "TTW$count";
  String setTeam2Won(int count) => "TTw$count"; // lowercase 'w'

  // Timeout (1 = Blue, 2 = Green)
  String setTeam1Timeout(int value) => "TTO1$value";
  String setTeam2Timeout(int value) => "TTO2$value";

  // Timer
  String setTimerMinutes(int minutes) => "TTTN$minutes";
  String startTimer() => "TTTS";
  String pauseTimer() => "TTTP";
  String resetTimer() => "TTTR";

  // Serve (1 = Team1, 2 = Team2)
  String setServe(int team) => "TTSV$team";

  // Match (1-7)
  String setMatch(int match) => "TTMH$match";

  // Brightness (0-255)
  String setBrightness(int value) => "TTBS$value";

  // Reset
  String resetScreen() => "TTRT";
}
