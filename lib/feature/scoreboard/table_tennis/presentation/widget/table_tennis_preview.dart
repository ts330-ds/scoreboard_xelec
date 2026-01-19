import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/table_tennis_team_panal.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/top_bar_dots.dart';

class TableTennisPreview extends StatelessWidget {
  const TableTennisPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black,
      child: Column(
        children: [
          TopBar(),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: const [
                Expanded(
                  child: TableTennisTeamPanel(
                    isTeam1: true,

                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: TableTennisTeamPanel(
                    isTeam1: false,

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
