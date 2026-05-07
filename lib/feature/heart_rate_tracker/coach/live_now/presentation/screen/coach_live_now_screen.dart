import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/coach_live_now_cubit.dart';
import '../layout/coach_live_now_mobile.dart';

class CoachLiveNowScreen extends StatelessWidget {
  const CoachLiveNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoachLiveNowCubit>(),
      child: const CoachLiveNowMobile(),
    );
  }
}
