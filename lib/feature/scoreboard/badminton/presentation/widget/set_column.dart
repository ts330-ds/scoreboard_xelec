import 'package:flutter/material.dart';
class SetColumn extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final bool showTick;

  const SetColumn({
    super.key,
    required this.title,
    required this.score,
    required this.color,
    required this.showTick,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.orange, width: 2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              score.toString().padLeft(2, '0'),
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showTick) ...[
              const SizedBox(height: 8),
              const Icon(
                Icons.check_circle,
                color: Colors.orange,
                size: 26,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
