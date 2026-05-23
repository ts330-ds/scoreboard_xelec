import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import '../cubit/history_state.dart';

class RangePresetChips extends StatelessWidget {
  final RangePreset selected;
  final DateTime? customFrom;
  final DateTime? customTo;
  final ValueChanged<RangePreset> onSelect;
  final VoidCallback onCustomTap;
  final VoidCallback? onFetchFromDevice;
  final bool canFetch;

  const RangePresetChips({
    super.key,
    required this.selected,
    required this.customFrom,
    required this.customTo,
    required this.onSelect,
    required this.onCustomTap,
    required this.onFetchFromDevice,
    required this.canFetch,
  });

  String _customLabel() {
    if (customFrom == null && customTo == null) return 'Custom';
    final fmt = DateFormat('dd MMM');
    final f = customFrom != null ? fmt.format(customFrom!) : '…';
    final t = customTo != null ? fmt.format(customTo!) : 'today';
    return '$f – $t';
  }

  @override
  Widget build(BuildContext context) {
    final presets = const [
      (RangePreset.last1h, '1h'),
      (RangePreset.last2h, '2h'),
      (RangePreset.last4h, '4h'),
      (RangePreset.last6h, '6h'),
      (RangePreset.last24h, '24h'),
      (RangePreset.last7d, '7d'),
      (RangePreset.last30d, '30d'),
      (RangePreset.all, 'All'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in presets) ...[
                _Chip(
                  label: p.$2,
                  selected: selected == p.$1,
                  onTap: () => onSelect(p.$1),
                ),
                const SizedBox(width: 8),
              ],
              _Chip(
                label: _customLabel(),
                selected: selected == RangePreset.custom,
                icon: Icons.date_range,
                onTap: onCustomTap,
              ),
            ],
          ),
        ),
        if (onFetchFromDevice != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canFetch ? onFetchFromDevice : null,
              icon: const Icon(Icons.cloud_download_outlined, size: 16),
              label: Text(
                canFetch
                    ? 'Fetch this range from device'
                    : 'Connect device to fetch',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: canFetch
                        ? AppColors.primary
                        : AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : AppColors.subtext),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.subtext,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
