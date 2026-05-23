import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ExitAwareTab — Shared wrapper for all 4 timing gate tabs
//
// PROBLEM YEH THI:
//   PopScope sirf ACTIVE ROUTE ke widget tree mein kaam karta hai.
//   TimingGateMainMobile ShellRoute ka persistent body hai — GoRouter
//   route pop karte waqt uska PopScope check nahi karta.
//
// SOLUTION:
//   Har tab screen ko ExitAwareTab se wrap karo. Jab bhi us tab pe
//   back press hoga, yeh dialog dikhaega.
//
// USAGE:
//   return ExitAwareTab(child: Scaffold(...));
//
// ══════════════════════════════════════════════════════════════════════════════
class ExitAwareTab extends StatelessWidget {
  final Widget child;
  const ExitAwareTab({super.key, required this.child});

  static const _primary = Color(0xFF1A73E8);
  static const _subtext = Color(0xFF6B7A8D);

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: _primary),
            SizedBox(width: 10),
            Text(
              'Exit App?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit Sports IQ?',
          style: TextStyle(color: _subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope active route ke widget tree mein hai — ab kaam karega ✅
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: child,
    );
  }
}
