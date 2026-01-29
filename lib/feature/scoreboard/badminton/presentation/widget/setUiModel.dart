enum PlayerType { player1, player2 }

class SetUIModel {
  final int player1Score;
  final int player2Score;
  final PlayerType? winner; // null = undecided

  const SetUIModel({
    this.player1Score = 0,
    this.player2Score = 0,
    this.winner,
  });
}