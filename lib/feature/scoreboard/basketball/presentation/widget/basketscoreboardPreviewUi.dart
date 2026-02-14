import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/quarter_dot_widget.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalCubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalState.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/shot_clock/shot_clock_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/shot_clock/shot_clock_state.dart';

import '../../../../../utility/appColor.dart';
import '../../../../../utility/universal_method.dart';
import '../cubit/timer/basketball_timer_cubit.dart';
import '../cubit/timer/basketball_timer_state.dart';

class BasketScoreboardPreviewUI extends StatelessWidget {
  const BasketScoreboardPreviewUI({super.key});
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridSize = screenWidth * 0.15;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          BlocBuilder<BasketControlPanelCubit,ControlPanelState>(
            builder: (context,snapshot) {
              return _teamScore(teamName: snapshot.team1Name, score: snapshot.team1Score.toString(), teamColor:
              snapshot.team1Color);
            }
          ),
          _centerSection(gridSize,context),
          BlocBuilder<BasketControlPanelCubit,ControlPanelState>(
              builder: (context,snapshot) {
                return _teamScore(teamName: snapshot.team2Name, score: snapshot.team2Score.toString(), teamColor:
                snapshot.team2Color);
              }
          ),
        ],
      ),
    );
  }

  Widget _teamScore({required String teamName, required String score, required Color teamColor}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: TextStyle(color: teamColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.maxFinite,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardDark, width: 3),
            ),
            child: Text(
              score,
              style: const TextStyle(color: Colors.red, fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerSection(double width,BuildContext ctx) {
    final bleCubit = ctx.read<BleCubit>();
    return BlocBuilder<BasketBallTimerCubit, BasketBallTimerState>(
      builder: (context, snapshot) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: width,
                      child: QuarterGridDots<BasketBallTimerCubit,BasketBallTimerState>(quarterSelector: (state) => state.quarter,
                        totalQuarter: 4,
                        isTimerFinishedSelector: (state) => state.status == TimerStatus.finished,
                      ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatTime(snapshot.seconds),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Shot Clock Timer Button
                  GestureDetector(
                  //  onTap: () => context.read<ShotClockCubit>().reset(),
                    child: BlocBuilder<ShotClockCubit, ShotClockState>(
                      builder: (context, state) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                          decoration: BoxDecoration(
                            color: state.status == ShotClockStatus.expired ? Colors.grey : Colors.red, 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            state.seconds.toString().padLeft(2, '0'),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
