import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/player_row.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/setUiModel.dart';
class ScoreBoardCard extends StatelessWidget {
  const ScoreBoardCard({super.key});

  @override
  Widget build(BuildContext context) {
    /// 🔥 This will come from Cubit later
    final sets = [
      const SetUIModel(winner: PlayerType.player1),
      const SetUIModel(winner: PlayerType.player2),
      const SetUIModel(winner: null),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        children: [
          PlayerRow(
            playerType: PlayerType.player1,
            playerName: "Player 1",
            color: Colors.green,
            sets: sets,
          ),
          const Divider(color: Colors.orange, thickness: 3),
          PlayerRow(
            playerType: PlayerType.player2,
            playerName: "Player 2",
            color: Colors.red,
            sets: sets,
          ),
        ],
      ),
    );
  }
}
