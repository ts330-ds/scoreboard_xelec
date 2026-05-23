import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';

class TimeOfDaySection extends StatelessWidget {
  final List<TimeSlotStats> slots;
  const TimeOfDaySection({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: slots.map((s) => _TimeSlotCard(slot: s)).toList(),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final TimeSlotStats slot;
  const _TimeSlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: slot.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(slot.icon, color: slot.color, size: 18),
              const SizedBox(width: 6),
              Text(slot.label,
                  style: TextStyle(
                      color: slot.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                slot.avgHr > 0 ? '${slot.avgHr}' : '--',
                style: TextStyle(
                    color:
                        slot.avgHr > 0 ? AppColors.text : AppColors.textHint,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('bpm',
                    style: TextStyle(
                        color: slot.color.withValues(alpha: 0.7),
                        fontSize: 10)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(slot.timeRange,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
