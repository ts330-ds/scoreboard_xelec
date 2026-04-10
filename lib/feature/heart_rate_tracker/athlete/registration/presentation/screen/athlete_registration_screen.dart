import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/registration/presentation/layout/athlete_registration_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class AthleteRegistrationScreen extends StatelessWidget {
  const AthleteRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  AthleteRegistrationMobile(),
      tablet:  AthleteRegistrationMobile(),
      desktop: AthleteRegistrationMobile(),
    );
  }
}
