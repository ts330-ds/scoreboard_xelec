import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class FeatureSelectionScreen extends StatelessWidget {
  const FeatureSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Feature',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeatureCard(
              title: 'Smart Scoreboard and Timer',
              icon: Icons.scoreboard_outlined,
              color: Colors.orange,
              onTap: () => context.push(
                '${AppPaths.deviceSelection}?feature=scoreboard',
              ),
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              title: 'Heart Rate Sensors',
              icon: Icons.timer_outlined,
              color: Colors.blue,
              onTap: () {
                //error_cubit.showWarning("Coming Soon, Time Gate feature is under development and will be available in a future update.");
                context.push(HeartTrackerPaths.chooseProfile);
              },
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              title: 'Electronic Timing Gates',
              icon: Icons.favorite_outline,
              color: Colors.red,
              onTap: () => context.push(HeartTrackerPaths.chooseProfile),
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              title: 'VBT ( Velocity-Based Training )',
              icon: Icons.fitness_center,
              color: Colors.green,
              onTap: () => context.push(HeartTrackerPaths.chooseProfile),
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              title: 'EEG ( Electroencephalography )',
              icon: Icons.psychology_outlined,
              color: Colors.purple,
              onTap: () => context.push(HeartTrackerPaths.chooseProfile),
            ),
            const SizedBox(height: 24),
            _FeatureCard(
              title: 'AMS ( Athlete Management System )',
              icon: Icons.manage_accounts,
              color: Colors.cyan,
              onTap: () => context.push(HeartTrackerPaths.chooseProfile),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
