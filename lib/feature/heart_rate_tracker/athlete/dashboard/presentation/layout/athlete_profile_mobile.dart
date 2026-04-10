import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class AthleteProfileMobile extends StatelessWidget {
  const AthleteProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Profile',
      bodyBackground: AppColors.bg,
      appBarBackground: AppColors.primary,
      onSettingsPressed: () {},
      settingsIcon: const Icon(Icons.bluetooth),
      body: const Center(
        child: Text(
          'Profile screen coming soon.',
          style: TextStyle(color: AppColors.subtext, fontSize: 14),
        ),
      ),
    );
  }
}
