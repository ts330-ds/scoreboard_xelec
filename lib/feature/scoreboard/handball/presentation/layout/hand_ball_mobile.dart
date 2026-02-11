import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/hand_ball_control_panal.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/hand_ball_scoreboard_preview.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/hand_ball_timer_control_row.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

import '../../../../../service/dependency_injection/di_service.dart';

class HandBallMobile extends StatelessWidget {
  const HandBallMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final controlCubit = sl<HandBallControlCubit>();
    final timerCubit = sl<HandBallTimerCubit>();
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
              controlCubit.exit();
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
        title: "Hand Ball",
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const HandballScoreboardPreview(),
            SizedBox(height: 10.h),
            const HandBallTimerControlRow(),
            SizedBox(height: 10.h),
            const Expanded(child: HandBallControlPanal()),
          ],
        ),
      ),
    );
  }
}
