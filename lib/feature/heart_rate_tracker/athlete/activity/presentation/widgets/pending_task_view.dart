import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'activity_constants.dart';

class PendingTaskView extends StatelessWidget {
  final AthleteActivityState state;
  const PendingTaskView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final type = typeFor(state.selectedActivity);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: type.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(type.icon, color: type.color, size: 36),
          ),

          const SizedBox(height: 20),

          Text(
            state.taskName.isNotEmpty ? state.taskName : state.selectedActivity,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // ── Details chips
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(
                icon: type.icon,
                label: state.selectedActivity,
                color: type.color,
              ),
              if (state.lat != null && state.lng != null && state.locationText.isNotEmpty)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: state.locationText,
                  color: AppColors.subtext,
                ),
            ],
          ),

          const SizedBox(height: 40),

          // ── Start Session button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                final isConnected = sl<HeartBleCubit>().state.isConnected;
                if (!isConnected) {
                  _showBleNotConnectedDialog(context);
                  return;
                }
                context.read<AthleteActivityCubit>().startSession();
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Start ${state.selectedActivity}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

void _showBleNotConnectedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.bluetooth_disabled, color: Colors.red, size: 22),
          SizedBox(width: 10),
          Text(
            'Device Not Connected',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Heart rate monitor is not connected.\nConnect your BLE device before starting a session so that heart rate can be tracked.',
        style: TextStyle(color: AppColors.subtext, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
