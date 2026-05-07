import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/coach_request_cubit.dart';
import '../layout/coach_athlete_search_mobile.dart';

class CoachAthleteSearchScreen extends StatelessWidget {
  const CoachAthleteSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoachRequestCubit>(),
      child: const CoachAthleteSearchMobile(),
    );
  }
}
