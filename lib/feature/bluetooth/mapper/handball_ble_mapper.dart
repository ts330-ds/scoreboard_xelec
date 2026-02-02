class HandBallBleMapper {
  // Team Names
  String setTeam1Name(String name) => "HBN1$name";
  String setTeam2Name(String name) => "HBN2$name";

  // Scores
  String setTeam1Score(int score) => "HBS1$score";
  String setTeam2Score(int score) => "HBS2$score";

  // Quarters (1-4)
  String setQuarter1() => "HBQ1";
  String setQuarter2() => "HBQ2";
  String setQuarter3() => "HBQ3";
  String setQuarter4() => "HBQ4";
  String setQuarter(int q) => "HBQ$q";

  // Timer
  String setTimerMinutes(int minutes) => "HBTN$minutes";
  String startTimer() => "HBTS";
  String pauseTimer() => "HBTP";
  String resetTimer() => "HBTR";

  // Timeout (Team 1: HBO1, HBO2, HBO3)
  String setTeam1Timeout1() => "HBO1";
  String setTeam1Timeout2() => "HBO2";
  String setTeam1Timeout3() => "HBO3";
  String setTeam1Timeout(int count) => "HBO$count";

  // Timeout (Team 2: HBo1, HBo2, HBo3) - lowercase 'o'
  String setTeam2Timeout1() => "HBo1";
  String setTeam2Timeout2() => "HBo2";
  String setTeam2Timeout3() => "HBo3";
  String setTeam2Timeout(int count) => "HBo$count";

  // 7 Meter
  String setTeam1SevenMeter(int value) => "HBSM$value";
  String setTeam2SevenMeter(int value) => "HBSm$value";

  // Suspension (1 = Red, 2 = Green)
  String setTeam1Suspension(int value) => "HBU1$value";
  String setTeam2Suspension(int value) => "HBU2$value";

  // Reset
  String resetScreen() => "HBRT";

// NOTE: Brightness & Buzzer NOT supported in Handball firmware
}
