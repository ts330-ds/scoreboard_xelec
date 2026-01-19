import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';


class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: context.text.bodyLarge!.copyWith(color: context.colors.surface)),
        const SizedBox(width: 6),
        Container(
          width: 36,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
