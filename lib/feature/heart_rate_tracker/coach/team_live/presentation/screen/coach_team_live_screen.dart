import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/coach_team_live_cubit.dart';
import '../layout/coach_team_live_mobile.dart';

class CoachTeamLiveScreen extends StatelessWidget {
  const CoachTeamLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoachTeamLiveCubit>()..startWatching(),
      child: const CoachTeamLiveMobile(),
    );
  }
}
