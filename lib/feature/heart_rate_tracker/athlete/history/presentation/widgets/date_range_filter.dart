import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onClear;

  const DateRangeFilter({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClear,
  });

  Future<void> _pick(BuildContext context, DateTime? initial,
      ValueChanged<DateTime?> onChange) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final hasFilter = fromDate != null || toDate != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateCell(
              label: fromDate != null ? fmt.format(fromDate!) : 'From',
              hasValue: fromDate != null,
              onTap: () => _pick(context, fromDate, onFromChanged),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 12, color: AppColors.subtext),
          ),
          Expanded(
            child: _DateCell(
              label: toDate != null ? fmt.format(toDate!) : 'To',
              hasValue: toDate != null,
              onTap: () => _pick(context, toDate, onToChanged),
            ),
          ),
          if (hasFilter)
            GestureDetector(
              onTap: onClear,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, size: 14, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  const _DateCell({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: hasValue ? AppColors.text : AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
