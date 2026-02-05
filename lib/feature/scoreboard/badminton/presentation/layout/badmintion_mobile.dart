import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/cubit/controller/badminton_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/badminton_control_panal.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/scoreboard_card.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class BadmintionMobile extends StatelessWidget {
  const BadmintionMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<BadmintonControllerCubit>();

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
          context.pop();
        }
      },
      child: AdaptiveScaffold(
        title: "Badminton",
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            ScoreBoardCard(),
            Expanded(child: BadmintonControlPanelUI()),
          ],
        ),
      ),
    );
  }
}
