import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/widget/hockey_scoreboard_preview.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/widget/hockey_timer_control_row.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/hockey_controller_cubit.dart';
import '../widget/hockey_control_panal.dart';

class HockeyMobile extends StatelessWidget {
  const HockeyMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<HockeyControllerCubit>();
    final timerCubit = sl<HockeyTimerCubit>();
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
              cubit.exit();
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
        title: "Hockey",
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HockeyScoreboardPreview(),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: ControllerHeading(text: "Timer"),
            ),
            SizedBox(height: 10.h),
            const HockeyTimerControlRow(),
            SizedBox(height: 10.h),
            const Expanded(flex: 6, child: HockeyControlPanal()),
          ],
        ),
      ),
    );
  }
}
