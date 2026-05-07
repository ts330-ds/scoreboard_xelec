import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/entity/athlete_search_entity.dart';
import '../cubit/coach_request_cubit.dart';
import '../layout/coach_send_request_mobile.dart';

class CoachSendRequestScreen extends StatelessWidget {
  final AthleteSearchEntity athlete;

  const CoachSendRequestScreen({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoachRequestCubit>(),
      child: CoachSendRequestMobile(athlete: athlete),
    );
  }
}
