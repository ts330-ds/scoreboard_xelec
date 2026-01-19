import 'package:flutter/material.dart';
class ScoreControl extends StatelessWidget {
  final String teamLabel;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ScoreControl({
    super.key,
    required this.teamLabel,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: _scoreButton(
                label: "${teamLabel} +",
                onPressed: onIncrement,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _scoreButton(
                label: "${teamLabel} -",
                onPressed: onDecrement,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scoreButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
