import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class ActivityEmptyState extends StatelessWidget {
  final VoidCallback onStartTap;
  const ActivityEmptyState({super.key, required this.onStartTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_run,
                color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Activities Yet',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "New" to start your first training session',
            style: TextStyle(color: AppColors.subtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onStartTap,
            icon: const Icon(Icons.add),
            label: const Text('Start Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
