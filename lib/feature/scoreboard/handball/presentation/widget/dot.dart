import 'package:flutter/material.dart';

class TimeoutDots extends StatelessWidget {
  final int timeout; // 0 → 3

  const TimeoutDots({
    super.key,
    required this.timeout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final bool isActive = index < timeout;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}
