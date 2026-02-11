import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/cubit/controller/universal_game_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/universal_game_board.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/universal_game_control_panal_ui.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

import '../../../../../service/dependency_injection/di_service.dart';

class UniversalGameMobile extends StatelessWidget {
  const UniversalGameMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<UniversalGameControllerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the scoreboard? Any unsaved progress may be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              cubit.resetMatch();
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
        title: "Universal Game",
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            UniversalGameBoard(),
            Expanded(
              flex: 6,
              child: UniversalGameControllerPanel()
            ),
          ],
        ),
      ),
    );
  }
}
