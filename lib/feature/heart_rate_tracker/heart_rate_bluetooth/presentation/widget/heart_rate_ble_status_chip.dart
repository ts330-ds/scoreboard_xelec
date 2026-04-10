import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class HeartBleStatusChip extends StatelessWidget {
  final bool isConnected;
  final String status;
  final String? deviceName;

  const HeartBleStatusChip({
    super.key,
    required this.isConnected,
    required this.status,
    this.deviceName,
  });

  Color get _dotColor {
    if (isConnected) return AppColors.success;
    if (status.toLowerCase().contains('scan') ||
        status.toLowerCase().contains('connect')) {
      return AppColors.warning;
    }
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final label = isConnected
        ? 'Connected${deviceName != null ? ' · $deviceName' : ''}'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
              boxShadow: [
                BoxShadow(
                  color: _dotColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            label,
            style: TextStyle(
              color: isConnected ? AppColors.success : AppColors.subtext,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (isConnected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.bluetooth_connected,
              color: AppColors.success,
              size: 14,
            ),
          ],
        ],
      ),
    );
  }
}
