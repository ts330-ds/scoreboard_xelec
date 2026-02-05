import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/widget/hockey_scoreboard_preview.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/widget/hockey_timer_control_row.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/hockey_controller_cubit.dart';
import '../widget/hockey_control_panal.dart';

class HockeyMobile extends StatelessWidget {
  const HockeyMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<HockeyControllerCubit>();
    final timer_cubit = sl<HockeyTimerCubit>();
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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ControllerHeading(text: "Timer"),
            ),
            const SizedBox(height: 10),
            const HockeyTimerControlRow(),
            const SizedBox(height: 10),
            const Expanded(flex: 6, child: HockeyControlPanal()),
          ],
        ),
      ),
    );
  }
}
