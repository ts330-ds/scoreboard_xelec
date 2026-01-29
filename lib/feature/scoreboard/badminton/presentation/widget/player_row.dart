import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/player_info_section.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/setUiModel.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/set_column.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/vertical_divider.dart';

class PlayerRow extends StatelessWidget {
  final PlayerType playerType;
  final String playerName;
  final Color color;
  final List<SetUIModel> sets;

  const PlayerRow({
    super.key,
    required this.playerType,
    required this.playerName,
    required this.color,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          PlayerInfoSection(
            playerName: playerName,
            scoreColor: color,
          ),
          for (int i = 0; i < sets.length; i++) ...[
            SetColumn(
              title: "S${i + 1}",
              score: playerType == PlayerType.player1
                  ? sets[i].player1Score
                  : sets[i].player2Score,
              color: color,
              showTick: sets[i].winner == playerType,
            ),
            if (i != sets.length - 1)
              const VerticalDividerWidget(),
          ]
        ],
      ),
    );
  }
}
