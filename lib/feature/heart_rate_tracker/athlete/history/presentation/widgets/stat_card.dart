import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const StatCard(this.label, this.value, this.unit, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          if (unit.isNotEmpty)
            Text(unit,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 9)),
        ],
      ),
    );
  }
}
