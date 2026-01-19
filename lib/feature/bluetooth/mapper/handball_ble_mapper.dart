class HandBallBleMapper {

  // ================= TEAM NAMES =================
  String setTeam1Name(String name) => "HBTM1:$name";
  String setTeam2Name(String name) => "HBTM2:$name";

  // ================= TEAM SCORES =================
  String setTeam1Score(int score) => "HBTM1SCORE:$score";
  String setTeam2Score(int score) => "HBTM2SCORE:$score";

  // ================= TEAM COLORS =================
  String setTeam1Color(String hex) => "HBTM1COLOR:$hex";
  String setTeam2Color(String hex) => "HBTM2COLOR:$hex";

  // ================= QUARTER =================
  String setQuarter(int qtr) => "HBQTR:$qtr";

  // ================= TIMER =================
  String startTimer() => "HBTIMERSTART";
  String stopTimer() => "HBTIMERSTOP";

  // ================= TIMEOUT =================
  String setTeam1Timeout(int count) => "HBTO1:$count";
  String setTeam2Timeout(int count) => "HBTO2:$count";

  // ================= 7 MINUTE PENALTY =================
  String setTeam1SevenMinute(bool active) =>
      "HB7M1:${active ? 1 : 0}";

  String setTeam2SevenMinute(bool active) =>
      "HB7M2:${active ? 1 : 0}";

  // ================= SUSPENSION =================
  String setTeam1Suspension(bool active) =>
      "HBS1:${active ? 1 : 0}";

  String setTeam2Suspension(bool active) =>
      "HBS2:${active ? 1 : 0}";
}
