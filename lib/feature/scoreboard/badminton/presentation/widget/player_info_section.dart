import 'package:flutter/material.dart';
class PlayerInfoSection extends StatelessWidget {
  final String playerName;
  final Color scoreColor;

  const PlayerInfoSection({
    super.key,
    required this.playerName,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              playerName,
              style: TextStyle(
                color: scoreColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.sports_tennis,
                    color: Colors.yellow, size: 40),
                const SizedBox(width: 20),
                Text(
                  "00",
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
