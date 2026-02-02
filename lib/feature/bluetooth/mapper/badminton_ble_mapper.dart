class BadmintonBleMapper {
  // MODE
  String enterBadmintonMode() => "BD";

  // TEAM NAMES
  String setTeam1Name(String name) => "BDN1$name";
  String setTeam2Name(String name) => "BDN2$name";

  // TEAM COLORS (RGB565 HEX)
  String setTeam1Color(String hex565) => "BDC1$hex565";
  String setTeam2Color(String hex565) => "BDC2$hex565";

  // SET SELECT
  String selectSet1() => "BDS1";
  String selectSet2() => "BDS2";
  String selectSet3() => "BDS3";

  // SET BrightNess
  String setBrightness(int value) => "BDBS:$value";
  // SCORES
  String setTeam1Score(int set, int score) => "BDS${set}A$score";
  String setTeam2Score(int set, int score) => "BDS${set}B$score";

  // SET WINNER (0 = clear, 1 = team1, 2 = team2)
  String setSetWinner(int set, int winner) => "BDW$set$winner";

  // RESET
  String resetMatch() => "BDRT";
}
