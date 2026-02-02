class HockeyBleMapper {
  // Team Names
  String setTeam1Name(String name) => "HON1$name";
  String setTeam2Name(String name) => "HON2$name";

  // Scores
  String setTeam1Score(int score) => "HOS1$score";
  String setTeam2Score(int score) => "HOS2$score";

  // Quarters (1-4)
  String setQuarter1() => "HOQ1";
  String setQuarter2() => "HOQ2";
  String setQuarter3() => "HOQ3";
  String setQuarter4() => "HOQ4";
  String setQuarter(int q) => "HOQ$q";

  // Timer
  String setTimerMinutes(int minutes) => "HOTN$minutes";
  String startTimer() => "HOTS";
  String pauseTimer() => "HOTP";
  String resetTimer() => "HOTR";

  // Penalty Corner
  String setTeam1PenaltyCorner(int value) => "HOP1$value";
  String setTeam2PenaltyCorner(int value) => "HOP2$value";

  // Shoot Out
  String setTeam1ShootOut(int value) => "HOO1$value";
  String setTeam2ShootOut(int value) => "HOO2$value";

  // Team Colors (RGB565 HEX)
  String setTeam1Color(String hex565) => "HOC1$hex565";
  String setTeam2Color(String hex565) => "HOC2$hex565";

  // Reset
  String resetScreen() => "HORT";

// NOTE: Brightness & Buzzer NOT supported in Hockey firmware
}
