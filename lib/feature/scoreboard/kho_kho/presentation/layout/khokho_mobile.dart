import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/cubit/timer/khokho_timer_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../widget/khokho_header.dart';
import '../widget/khokho_team_card.dart';
import '../widget/khokho_footer.dart';
import '../widget/khokho_control_panel.dart';
import '../cubit/controller/khokho_controller_cubit.dart';

class KhokhoMobile extends StatelessWidget {
  const KhokhoMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<KhokhoControllerCubit>();
    final timer_cubit = sl<KhokhoTimerCubit>();

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
              timer_cubit.resetToDefault();
              cubit.resetScreen();
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
          context.pop(true);
        }
      },
      child: AdaptiveScaffold(
        title: "Kho Kho",
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // Preview Area (Header + Score + Footer)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  const KhokhoHeader(),
                  Expanded(
                    child:
                        BlocBuilder<
                          KhokhoControllerCubit,
                          KhokhoControllerState
                        >(
                          builder: (context, state) {
                            return Row(
                              children: [
                                // Team 1 (Blue)
                                KhokhoTeamCard(
                                  teamName: state.team1Name,
                                  score: state.team1Score.toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  status: state.isTeam1Chasing
                                      ? "Chase"
                                      : "Defend",
                                  backgroundColor: state.team1Color,
                                  // Blue
                                  scoreBoxColor: const Color(0xFF2C5292),
                                  // Lighter Blue
                                  statusColor: state.isTeam1Chasing
                                      ? const Color(0xFFFFC107)
                                      : const Color(0xFF28A745),
                                ),

                                // Divider Line
                                const VerticalDivider(
                                  width: 2,
                                  color: Colors.black,
                                  thickness: 2,
                                ),

                                // Team 2 (Red)
                                KhokhoTeamCard(
                                  teamName: state.team2Name,
                                  score: state.team2Score.toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  status: state.isTeam1Chasing
                                      ? "Defend"
                                      : "Chase",
                                  backgroundColor: state.team2Color,
                                  // Red
                                  scoreBoxColor: const Color(0xFF8B0000),
                                  // Darker Red
                                  statusColor: state.isTeam1Chasing
                                      ? const Color(0xFF28A745)
                                      : const Color(0xFFFFC107),
                                ),
                              ],
                            );
                          },
                        ),
                  ),
                  const KhokhoFooter(),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.black),

            // Control Panel
            const Expanded(flex: 5, child: KhokhoControlPanel()),
          ],
        ),
      ),
    );
  }
}
