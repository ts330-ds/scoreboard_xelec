import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/notification/presentation/layout/athlete_notification_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class AthleteNotificationScreen extends StatelessWidget {
  const AthleteNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  const AthleteNotificationMobile(),
      tablet:  const AthleteNotificationMobile(),
      desktop: const AthleteNotificationMobile(),
    );
  }
}
