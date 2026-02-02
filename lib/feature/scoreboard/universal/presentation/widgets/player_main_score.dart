import 'package:flutter/material.dart';

class PlayerMainScore extends StatelessWidget {
  final String name;
  final Color color;
  final int score;

  const PlayerMainScore({
    super.key,
    required this.name,
    required this.color,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PLAYER NAME
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 4),

          /// MAIN SCORE (SELECTED SET SCORE)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                score.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
