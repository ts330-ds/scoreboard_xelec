import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.subtext,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600));
  }
}
