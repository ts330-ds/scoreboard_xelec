import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_dashboard_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  CoachDashboardMobile(),
      tablet:  CoachDashboardMobile(),
      desktop: CoachDashboardMobile(),
    );
  }
}
