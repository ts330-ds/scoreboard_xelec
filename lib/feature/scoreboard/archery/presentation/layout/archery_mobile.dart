import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/controller/archery_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../widget/archery_control_panel.dart';
import '../widget/archery_end_label.dart';
import '../widget/archery_player_indicator.dart';
import '../widget/archery_timer_display.dart';
import '../widget/archery_traffic_light.dart';

class ArcheryMobile extends StatelessWidget {
  const ArcheryMobile({super.key});


Future<bool?> _showExitDialog(BuildContext context) {
    final controllerCubit = sl<ArcheryControllerCubit>();
    final timerCubit = sl<ArcheryTimerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the scoreboard? Any unsaved progress may be lost.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              timerCubit.resetToDefault();
              controllerCubit.resetMatch();
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
        title: "Archery",
        appBarBackground: Colors.grey[900]!,
        bodyBackground: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top section - Timer and Traffic Light
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Timer Display
                      const Expanded(
      
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ArcheryEndLabel(),
                            SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ArcheryTimerDisplay(),
                            ),
                            SizedBox(height: 16),
                            ArcheryPlayerIndicator(),
                          ],
                        ),
                      ),
                      // Traffic Light
                      const Expanded(
                        flex: 1,
                        child: Center(
                          child: ArcheryTrafficLight(size: 50),
                        ),
                      ),
                    ],
                  ),
                ),
      
                // Control Panel
                const ArcheryControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
