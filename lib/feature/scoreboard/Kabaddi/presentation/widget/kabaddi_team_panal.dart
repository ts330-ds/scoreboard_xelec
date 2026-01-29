import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import 'package:xelex_esp/utility/universal_method.dart';

class TeamPanel extends StatelessWidget {
  final String teamName;
  final int score;
  final int touch;
  final int bonus;
  final int allOut;
  final Color backgroundColor;
  final Color scoreBackgroundColor;
  final bool showRunner;
  final Color teamNameColor;

  const TeamPanel({
    Key? key,
    required this.teamName,
    required this.score,
    required this.touch,
    required this.bonus,
    required this.allOut,
    required this.backgroundColor,
    required this.scoreBackgroundColor,
    required this.teamNameColor,
    this.showRunner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              teamName,
              style:  context.text.titleLarge?.copyWith(
                color: teamNameColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            widgetGap(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: scoreBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  score.toString().padLeft(2, '0'),
                  style: context.text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildStatRow('Touch', touch,context),
                    const SizedBox(height: 10),
                    _buildStatRow('Bonus', bonus,context),
                    const SizedBox(height: 10),
                    _buildStatRow('All Out', allOut,context),
                  ],
                ),
                if (showRunner) ...[
                  const SizedBox(height: 20),
                  Icon(
                    Icons.directions_run,
                    size: 80,
                    color: Colors.yellow,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, BuildContext context) {
    return Row(
      children: [
        Text(
            "$label:- ",
          style: context.text.titleSmall!.copyWith(fontSize: 16)
        ),
        Text(
          value.toString(),
          style: context.text.titleMedium
        ),
      ],
    );
  }
}