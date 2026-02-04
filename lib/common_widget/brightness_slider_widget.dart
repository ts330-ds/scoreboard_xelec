import 'package:flutter/material.dart';

class BrightnessSliderMinimal extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedEnd;

  const BrightnessSliderMinimal({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onChangedEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Text(
            'Brightness',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: const Color(0xFF3B82F6),
                inactiveTrackColor: const Color(0xFFE2E8F0),
                thumbColor: const Color(0xFF3B82F6),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                overlayColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              ),
              child: Slider(
                min: 0,
                max: 220,
                value: value,
                onChanged: onChanged,
                onChangeEnd: onChangedEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}