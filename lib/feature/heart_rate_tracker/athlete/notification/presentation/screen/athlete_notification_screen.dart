import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/notification/presentation/cubit/athlete_notification_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/notification/presentation/layout/athlete_notification_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteNotificationScreen extends StatelessWidget {
  const AthleteNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AthleteNotificationCubit>()..fetchRequests(),
      child: ResponsiveLayout(
        mobile: const AthleteNotificationMobile(),
        tablet: const AthleteNotificationMobile(),
        desktop: const AthleteNotificationMobile(),
      ),
    );
  }
}
