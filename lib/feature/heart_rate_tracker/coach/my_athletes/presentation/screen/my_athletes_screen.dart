import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/my_athletes_cubit.dart';
import '../layout/my_athletes_mobile.dart';

class MyAthletesScreen extends StatelessWidget {
  const MyAthletesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyAthletesCubit>(),
      child: const MyAthletesMobile(),
    );
  }
}
