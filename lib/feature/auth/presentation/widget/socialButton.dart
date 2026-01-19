import 'package:flutter/material.dart';

import '../../../../utility/appColor.dart';
class SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: AppColors.textPrimary),
        label: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
