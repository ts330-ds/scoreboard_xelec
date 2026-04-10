import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class HeartBleDeviceTile extends StatelessWidget {
  final String name;
  final String mac;
  final int rssi;
  final bool isPaired;
  final VoidCallback onTap;

  const HeartBleDeviceTile({
    super.key,
    required this.name,
    required this.mac,
    required this.rssi,
    required this.isPaired,
    required this.onTap,
  });

  String get _signalStrength {
    if (rssi >= -60) return 'Strong';
    if (rssi >= -70) return 'Good';
    return 'Weak';
  }

  Color get _signalColor {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -70) return AppColors.warning;
    return AppColors.error;
  }

  IconData get _signalIcon {
    if (rssi >= -60) return Icons.signal_cellular_alt;
    if (rssi >= -70) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaired
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            _buildDeviceIcon(),
            const SizedBox(width: 14),
            Expanded(child: _buildDeviceInfo()),
            _buildSignalStrength(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: const Icon(
        Icons.watch,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPaired) ...[
              const SizedBox(width: 8),
              _buildPairedBadge(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          mac,
          style: const TextStyle(
            color: AppColors.subtext,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPairedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Paired',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignalStrength() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _signalIcon,
          color: _signalColor,
          size: 18,
        ),
        const SizedBox(height: 2),
        Text(
          _signalStrength,
          style: TextStyle(
            color: _signalColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
