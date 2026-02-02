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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Visibility(
            visible: showTick,
            replacement: const SizedBox(
              height: 26,
              width: 26,
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.check_circle,
                color: Colors.orange,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
