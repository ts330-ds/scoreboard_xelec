import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/widget/timerControlButtons.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';

import '../../../../../../common_widget/controller_heading.dart';
import '../../../../../../service/dependency_injection/di_service.dart';
import '../../cubit/controlPanal/controlPanalCubit.dart';
import '../../cubit/controlPanal/controlPanalState.dart';
import '../../cubit/timer/basketball_timer_cubit.dart';
import '../../cubit/timer/basketball_timer_state.dart';
import '../../widget/basketscoreboardPreviewUi.dart';
import '../../widget/controlPanalUi.dart';

class BasketBallMobile extends StatelessWidget {
  const BasketBallMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final controller_cubit = sl<BasketControlPanelCubit>();
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
              controller_cubit.exit();
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
        title: "BasketBall",
        onSettingsPressed: () {
          context.push(AppPaths.basketballConfig);
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BasketScoreboardPreviewUI(),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ControllerHeading(text: "Timer"),
            ),
            const SizedBox(height: 10),
            const BasketBallTimerControlRow(),
            Expanded(
              flex: 6,
              child: MultiBlocListener(
                listeners: [
                  /// Listen Timer changes
                  BlocListener<BasketBallTimerCubit, BasketBallTimerState>(
                    listener: (context, timerState) {},
                  ),

                  /// Listen Control Panel changes
                  BlocListener<BasketControlPanelCubit, ControlPanelState>(
                    listener: (context, controlState) {},
                  ),
                ],
                child: const BasketBallControlPanelUI(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
