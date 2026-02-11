import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/controller/archery_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
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
        content: const Text(
          'Are you sure you want to close the scoreboard? Any unsaved progress may be lost.',
        ),
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
        appBarBackground: Colors.black,
        textColor: Colors.white,
        bodyBackground: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Top section - Timer and Traffic Light
                Expanded(
                  child: Row(
                    children: [
                      // Timer Display
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ArcheryEndLabel(),
                            SizedBox(height: 8.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ArcheryTimerDisplay(),
                            ),
                            SizedBox(height: 8.h),
                            ArcheryPlayerIndicator(),
                          ],
                        ),
                      ),
                      // Traffic Light
                      Center(child: ArcheryTrafficLight(size: 40.w)),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                ArcheryControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
