import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/center_panal.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/team_panal.dart';

import '../cubit/controller/hand_ball_controller_state.dart';

class HandballScoreboardPreview extends StatelessWidget {
  const HandballScoreboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<HandBallControlCubit, HandballControlState>(
              builder: (context, snapshot) {
                return TeamPanel(
                  teamName: snapshot.team1Name,
                  score: snapshot.team1Score,
                  timeout: snapshot.team1Timeout,
                  sevenM: snapshot.team1_7m,
                  suspension: snapshot.team1Suspension ? 1 : 0,
                  titleColor: snapshot.team1Color,
                );
              },
            ),
          ),
          HandBallCenterPanel(),
          Expanded(
            child: BlocBuilder<HandBallControlCubit, HandballControlState>(
              builder: (context, snapshot) {
                return TeamPanel(
                  teamName: snapshot.team2Name,
                  score: snapshot.team2Score,
                  timeout: snapshot.team2Timeout,
                  sevenM: snapshot.team2_7m,
                  suspension: snapshot.team2Suspension ? 1 : 0,
                  titleColor: snapshot.team2Color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
