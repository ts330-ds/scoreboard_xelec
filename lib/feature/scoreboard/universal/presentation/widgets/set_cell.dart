import 'package:flutter/material.dart';
class SetCell extends StatelessWidget {
  final int setNo;
  final String score;
  final Color color;
  final bool showTick;

  const SetCell({
    super.key,
    required this.setNo,
    required this.score,
    required this.color,
    required this.showTick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// SET NUMBER
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "S$setNo",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          /// SCORE (AUTO-SCALED)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              score,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// TICK
          showTick
              ? const Icon(
            Icons.check_circle,
            color: Colors.orange,
            size: 18,
          )
              : const SizedBox(height: 18),
        ],
      ),
    );
  }
}
