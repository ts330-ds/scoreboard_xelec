import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/registration/presentation/layout/coach_registration_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class CoachRegistrationScreen extends StatelessWidget {
  const CoachRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile:  CoachRegistrationMobile(),
      tablet:  CoachRegistrationMobile(),
      desktop: CoachRegistrationMobile(),
    );
  }
}
