import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';


class BadmintionTablet extends StatelessWidget {
  const BadmintionTablet({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to close the scoreboard? Any unsaved progress may be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
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

            ],
          )
      ),
    );
  }
}
