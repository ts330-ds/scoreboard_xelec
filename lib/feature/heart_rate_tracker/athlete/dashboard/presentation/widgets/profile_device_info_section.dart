import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class ProfileDeviceInfoSection extends StatelessWidget {
  const ProfileDeviceInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeartBleCubit, HeartBleState>(
      // HeartBleState har HR/RR/step reading pe badalta hai (per-second).
      // Ye card sirf in 4 fields ko dikhata hai — baaki changes pe rebuild
      // mat karo, warna scroll ke dauraan constant rebuild se lag aata hai.
      buildWhen: (prev, curr) =>
          prev.isConnected != curr.isConnected ||
          prev.modelName != curr.modelName ||
          prev.serialNumber != curr.serialNumber ||
          prev.firmwareVersion != curr.firmwareVersion,
      builder: (context, ble) {
        final isConnected = ble.isConnected;
        final model = ble.modelName.isNotEmpty ? ble.modelName : null;
        final serial = ble.serialNumber.isNotEmpty ? ble.serialNumber : null;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'DEVICE INFO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtext,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppColors.successBg
                            : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isConnected ? 'Connected' : 'Not Connected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isConnected
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    ProfileDeviceInfoRow(
                      icon: Icons.devices_outlined,
                      label: 'Device Model',
                      value: model ?? '—',
                    ),
                    const SizedBox(height: 12),
                    ProfileDeviceInfoRow(
                      icon: Icons.qr_code_outlined,
                      label: 'Serial Number',
                      value: serial ?? '—',
                    ),
                    if (ble.firmwareVersion.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ProfileDeviceInfoRow(
                        icon: Icons.memory_outlined,
                        label: 'Firmware',
                        value: ble.firmwareVersion,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileDeviceInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileDeviceInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.subtext),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
