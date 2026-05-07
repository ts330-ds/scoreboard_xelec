import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/entity/my_athlete_entity.dart';
import '../cubit/athlete_detail_cubit.dart';
import '../cubit/athlete_health_metrics_cubit.dart';
import '../cubit/my_athletes_cubit.dart';
import '../layout/athlete_detail_mobile.dart';

class AthleteDetailScreen extends StatelessWidget {
  final MyAthleteEntity preview;
  final MyAthletesCubit listCubit;

  const AthleteDetailScreen({
    super.key,
    required this.preview,
    required this.listCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AthleteDetailCubit>()..fetchDetail(preview.id),
        ),
        BlocProvider(
          create: (_) => sl<AthleteHealthMetricsCubit>()
            ..fetchMetrics(
              preview.id,
              fromDate: DateTime.now().subtract(const Duration(days: 6)),
              toDate: DateTime.now(),
            ),
        ),
        BlocProvider.value(value: listCubit),
      ],
      child: AthleteDetailMobile(preview: preview),
    );
  }
}
