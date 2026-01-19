import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/stat_row.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import 'dot.dart';

class TeamPanel extends StatelessWidget {
  final String teamName;
  final int score;
  final int timeout;
  final int sevenM;
  final int suspension;
  final Color titleColor;

  const TeamPanel({
    super.key,
    required this.teamName,
    required this.score,
    required this.timeout,
    required this.sevenM,
    required this.suspension,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// TEAM NAME
        Text(
          teamName,
          style: context.text.titleSmall?.copyWith(color: titleColor),
        ),

        const SizedBox(height: 6),

        /// SCORE BOX
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              score.toString().padLeft(3, '0'),
              style: context.text.titleMedium!.copyWith(
                color: context.colors.surface,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// TIMEOUT DOTS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TO -',
              style: context.text.bodyLarge!
                  .copyWith(color: context.colors.surface),
            ),
            const SizedBox(width: 4),
           TimeoutDots(timeout: timeout)
          ],
        ),

        const SizedBox(height: 10),

        /// 7m
        StatRow(
          label: '7m -',
          value: sevenM.toString(),
          color: Colors.blue,
        ),

        const SizedBox(height: 10),

        /// Suspension
        StatRow(
          label: 'Susp.',
          value: suspension.toString(),
          color: Colors.red,
        ),
      ],
    );
  }
}
