import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/timer/football_timer_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/football_controller_state.dart';
import '../widget/football_team_card.dart';
import '../widget/football_center_panel.dart';
import '../widget/football_control_panel.dart';
import '../cubit/controller/football_controller_cubit.dart';

class FootballMobile extends StatelessWidget {
  const FootballMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<FootballControllerCubit>();
    final timerCubit = sl<FootballTimerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text(
          'Are you sure you want to close the scoreboard? Any unsaved progress may be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              timerCubit.resetToDefault();
              cubit.exit(); // Optional: Reset logic if needed
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
        title: "Football Scoreboard",
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // Preview Area
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.black,
                child:
                    BlocBuilder<
                      FootballControllerCubit,
                      FootballControllerState
                    >(
                      builder: (context, state) {
                        return Row(
                          children: [
                            // Team 1 - Now wrapped in Expanded for proper layout
                            Expanded(
                              child: FootballTeamCard(
                                teamName: state.team1Name,
                                score: state.team1Score.toString().padLeft(
                                  2,
                                  '0',
                                ),
                                teamNameColor: state.team1Color,
                              ),
                            ),

                            // Center Panel - Fixed width within the Row
                            FootballCenterPanel(),

                            // Team 2 - Now wrapped in Expanded for proper layout
                            Expanded(
                              child: FootballTeamCard(
                                teamName: state.team2Name,
                                score: state.team2Score.toString().padLeft(
                                  2,
                                  '0',
                                ),
                                teamNameColor: state.team2Color,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ),

            Divider(height: 1.h, color: Colors.grey),

            // Control Panel
            const Expanded(flex: 6, child: FootballControlPanel()),
          ],
        ),
      ),
    );
  }
}
