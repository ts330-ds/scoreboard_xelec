import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_main_screen_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class CoachDashboardScreen extends StatelessWidget {
  final Widget child;
  const CoachDashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  CoachMainScreenMobile(child: child),
      tablet:  CoachMainScreenMobile(child: child),
      desktop: CoachMainScreenMobile(child: child),
    );
  }
}
