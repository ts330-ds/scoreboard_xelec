import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class AthleteNotificationMobile extends StatelessWidget {
  const AthleteNotificationMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Notifications',
      appBarBackground: AppColors.primary,
      bodyBackground: AppColors.bg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationItem(
            icon: Icons.favorite,
            iconColor: AppColors.heartRed,
            title: 'High Heart Rate Alert',
            subtitle: 'Your heart rate exceeded 150 BPM during training.',
            time: '2 min ago',
            isUnread: true,
          ),
          _NotificationItem(
            icon: Icons.bluetooth_connected,
            iconColor: AppColors.success,
            title: 'Device Connected',
            subtitle: 'Your wearable device has been connected successfully.',
            time: '15 min ago',
            isUnread: true,
          ),
          _NotificationItem(
            icon: Icons.sync,
            iconColor: AppColors.primary,
            title: 'Data Synced',
            subtitle: 'Your health data has been synced to the server.',
            time: '1 hr ago',
            isUnread: false,
          ),
          _NotificationItem(
            icon: Icons.directions_walk,
            iconColor: AppColors.actSteps,
            title: 'Daily Step Goal Reached',
            subtitle: 'Congratulations! You have completed your 10,000 steps goal.',
            time: '3 hr ago',
            isUnread: false,
          ),
          _NotificationItem(
            icon: Icons.battery_alert,
            iconColor: AppColors.warning,
            title: 'Low Battery Warning',
            subtitle: 'Your wearable device battery is below 20%. Please charge it.',
            time: 'Yesterday',
            isUnread: false,
          ),
        ],
      ),
    );
  }
}

// ── Notification Item ────────────────────────────────────────────────────────
class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,,
    required this.subtitle,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppColors.primary.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.subtext, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
