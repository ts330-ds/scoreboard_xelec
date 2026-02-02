import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../cubit/controller/badminton_controller_state.dart';
class PlayerInfoSection extends StatelessWidget {
  final String playerName;
  final Color scoreColor;
  final bool isServe;
  final int score;

  const PlayerInfoSection({
    super.key,
    required this.playerName,
    required this.scoreColor,
    this.isServe = false,
    required this.score
  });


  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: TextStyle(
                color: scoreColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            widgetGap(),
            Row(
              children: [
                Text(
                  score.toString(),
                  style: context.text.titleLarge!.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 40
                  ),
                ),
                const SizedBox(width: 20),
                if(isServe)...[const Icon(Icons.sports_tennis,
                    color: Colors.yellow, size: 40)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
