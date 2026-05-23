import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class HistoryEmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const HistoryEmptyState({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
