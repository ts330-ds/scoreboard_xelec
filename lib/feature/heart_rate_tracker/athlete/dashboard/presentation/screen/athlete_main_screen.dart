import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_main_screen_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class AthleteMainScreen extends StatelessWidget {
  final Widget child;
  const AthleteMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  AthleteMainScreenMobile(child: child),
      tablet:  AthleteMainScreenMobile(child: child),
      desktop: AthleteMainScreenMobile(child: child),
    );
  }
}
