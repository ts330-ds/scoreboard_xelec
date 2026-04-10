import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';
import 'activity_constants.dart';

class ActivitySessionCard extends StatelessWidget {
  final ActivitySession session;
  const ActivitySessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final type = typeFor(session.activityType);
    final mins = session.actualDurationSeconds ~/ 60;
    final secs = session.actualDurationSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: type.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.icon, color: type.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.activityType,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${session.formattedDate}  •  ${session.formattedTime}',
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Completed',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ActivityStatChip(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value:
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                ActivityStatChip(
                  icon: Icons.favorite,
                  label: 'Avg HR',
                  value: session.avgHeartRate > 0
                      ? '${session.avgHeartRate} bpm'
                      : '--',
                  color: AppColors.heartRed,
                ),
                const SizedBox(width: 10),
                ActivityStatChip(
                  icon: Icons.trending_up,
                  label: 'Max HR',
                  value: session.maxHeartRate > 0
                      ? '${session.maxHeartRate} bpm'
                      : '--',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),

          // ── Location
          if (session.location.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.subtext),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(session.location,
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class ActivityStatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const ActivityStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
