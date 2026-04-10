import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/active_session_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/activity_session_list.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/new_activity_sheet.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class AthleteActivityMobile extends StatelessWidget {
  const AthleteActivityMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AthleteActivityCubit(),
      child: const _ActivityBody(),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<HeartBleCubit, HeartBleState>(
      listenWhen: (prev, curr) =>
          prev.heartRate != curr.heartRate && curr.heartRate > 0,
      listener: (context, bleState) {
        context.read<AthleteActivityCubit>().recordHeartRate(bleState.heartRate);
      },
      child: BlocBuilder<AthleteActivityCubit, AthleteActivityState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              title: const Text('Activity'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (!state.isSessionActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () => _showNewActivitySheet(context),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text('New',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
              ],
            ),
            body: state.isSessionActive
                ? ActiveSessionView(state: state)
                : ActivitySessionList(
                    sessions: state.sessions,
                    onStartTap: () => _showNewActivitySheet(context),
                  ),
          );
        },
      ),
    );
  }

  void _showNewActivitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AthleteActivityCubit>(),
        child: const NewActivitySheet(),
      ),
    );
  }
}
