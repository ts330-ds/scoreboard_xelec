import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/widget/kabaddi_control_panel.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../../../../common_widget/controller_heading.dart';
import '../../../../../responsive/adaptive_scaffold.dart';
import '../../../../../router/app_path.dart';
import '../../../../../utility/universal_method.dart';
import '../cubit/controller/kabaddi_controller_cubit.dart';
import '../cubit/controller/kabaddi_controller_state.dart';
import '../cubit/timer/kabaddi_timer_cubit.dart';
import '../cubit/timer/kabaddi_timer_state.dart';
import '../widget/kabaddi_header.dart';
import '../widget/kabaddi_team_panal.dart';


class KhabaddiMobile extends StatelessWidget {
  
  const KhabaddiMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final controller_cubit = sl<KabaddiControllerCubit>();
    final timer_cubit = sl<KabaddiTimerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the scoreboard? Any unsaved progress may be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              timer_cubit.resetToDefault();
              controller_cubit.resetScreen();
              context.pop(true);
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    GameState _gameState = GameState();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context) ?? false;
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: AdaptiveScaffold(
        title: "Kabaddi",
        resizeToAvoidBottomInset: false,

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            HeaderBar(
              timeInSeconds: _gameState.timeInSeconds,
              raid: _gameState.raid,
              currentPlayer: _gameState.currentPlayer,
            ),

            /// TEAMS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: BlocBuilder<KabaddiControllerCubit, KabaddiControllerState>(
                    builder: (context,snapshot) {
                      return TeamPanel(
                        teamName: snapshot.team1Name,
                        score: snapshot.team1Score,
                        touch: snapshot.team1Touch,
                        bonus: snapshot.team1Bonus,
                        allOut: snapshot.team1AllOut,
                        backgroundColor: const Color(0xFFB3D9FF),
                        scoreBackgroundColor: const Color(0xFF5A8DC8),
                        teamNameColor: snapshot.team1Color,
                        showRunner: snapshot.isRaiderOnTeam1,
                      );
                    }
                  ),
                ),

                const VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: Colors.black,
                ),

                Expanded(
                  child: BlocBuilder<KabaddiControllerCubit, KabaddiControllerState>(
                      builder: (context,snapshot) {
                        return TeamPanel(
                          teamName: snapshot.team2Name,
                          score: snapshot.team2Score,
                          touch: snapshot.team2Touch,
                          bonus: snapshot.team2Bonus,
                          allOut: snapshot.team2AllOut,
                          backgroundColor: const Color(0xFFB3D9FF),
                          scoreBackgroundColor: const Color(0xFF5A8DC8),
                          teamNameColor: snapshot.team2Color,
                          showRunner: !snapshot.isRaiderOnTeam1,
                        );
                      }
                  ),
                ),
              ],
            ),
            /// BOTTOM SECTION (Raid Timer / Controls / Debug)
            ///
            widgetGap(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ControllerHeading(text: "Match Timer"),
                  const SizedBox(height: 6),
                  BlocBuilder<KabaddiTimerCubit, KabaddiTimerState>(
                    builder: (context, state) {
                      final timerCubit = context.read<KabaddiTimerCubit>();
                      return Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: state.status == TimerStatus.running ? "Pause" : "Start",
                              backgroundColor: state.status == TimerStatus.running ? Colors.orange : Colors.green,
                              onPressed: () {
                                if (state.status == TimerStatus.running) {
                                  timerCubit.pause();
                                } else {
                                  timerCubit.start();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              label: "Reset",
                              backgroundColor: Colors.blueGrey,
                              onPressed: () => timerCubit.reset(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 6,
              child: KabaddiControlPanel(),
            ),
          ],
        )
      ),
    );

  }
}

class GameState {
  final int homeScore;
  final int awayScore;
  final int homeTouch;
  final int awayTouch;
  final int homeBonus;
  final int awayBonus;
  final int homeAllOut;
  final int awayAllOut;
  final int timeInSeconds;
  final int raid;
  final int currentPlayer; // 1 or 2

  GameState({
    this.homeScore = 0,
    this.awayScore = 0,
    this.homeTouch = 50,
    this.awayTouch = 50,
    this.homeBonus = 50,
    this.awayBonus = 50,
    this.homeAllOut = 50,
    this.awayAllOut = 50,
    this.timeInSeconds = 18,
    this.raid = 1,
    this.currentPlayer = 1,
  });

  GameState copyWith({
    int? homeScore,
    int? awayScore,
    int? homeTouch,
    int? awayTouch,
    int? homeBonus,
    int? awayBonus,
    int? homeAllOut,
    int? awayAllOut,
    int? timeInSeconds,
    int? raid,
    int? currentPlayer,
  }) {
    return GameState(
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeTouch: homeTouch ?? this.homeTouch,
      awayTouch: awayTouch ?? this.awayTouch,
      homeBonus: homeBonus ?? this.homeBonus,
      awayBonus: awayBonus ?? this.awayBonus,
      homeAllOut: homeAllOut ?? this.homeAllOut,
      awayAllOut: awayAllOut ?? this.awayAllOut,
      timeInSeconds: timeInSeconds ?? this.timeInSeconds,
      raid: raid ?? this.raid,
      currentPlayer: currentPlayer ?? this.currentPlayer,
    );
  }
}