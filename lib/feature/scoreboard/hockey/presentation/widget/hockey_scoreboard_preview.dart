import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/widget/hockey_team_panal.dart';

import 'hockey_center_panal.dart';




class HockeyScoreboardPreview extends StatelessWidget {
  const HockeyScoreboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Row(
        children:  [
          Expanded(
            child: HockeyTeamPanel(isTeam1: true,),
          ),

          HockeyCenterPanel(),

          Expanded(
            child: HockeyTeamPanel(isTeam1: false,),
          ),
        ],
      ),
    );
  }
}
