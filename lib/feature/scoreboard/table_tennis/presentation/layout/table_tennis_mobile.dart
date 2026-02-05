import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/screen/table_tennis_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/table_tennis_preview.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

import '../../../../../router/app_path.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../widget/table_tennis_control_panal.dart';

class TableTennisMobile extends StatelessWidget {
  const TableTennisMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final cubit = sl<TableTennisControllerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the scoreboard? Any unsaved progress may be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
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
        title: "Table Tennis",
        body: Column(
          children: [
            Expanded(flex: 4, child: TableTennisPreview()),
            Expanded(flex: 6,child: TableTennisControlPanal())
          ],
        ),
      ),
    );
  }
}
