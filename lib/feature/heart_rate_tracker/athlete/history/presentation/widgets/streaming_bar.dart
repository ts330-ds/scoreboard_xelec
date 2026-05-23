import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class StreamingBar extends StatelessWidget {
  final int count;
  const StreamingBar({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Streaming… $count readings received',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
