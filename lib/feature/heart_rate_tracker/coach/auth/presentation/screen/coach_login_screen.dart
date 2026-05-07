import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/layout/coach_login_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class CoachLoginScreen extends StatelessWidget {
  const CoachLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  CoachLoginMobile(),
      tablet:  CoachLoginMobile(),
      desktop: CoachLoginMobile(),
    );
  }
}
