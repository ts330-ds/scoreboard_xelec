import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/active_session_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/pending_task_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class AthleteTaskDetailScreen extends StatefulWidget {
  final AthleteTaskEntity task;
  final AthleteActivityCubit activityCubit;

  const AthleteTaskDetailScreen({
    super.key,
    required this.task,
    required this.activityCubit,
  });

  @override
  State<AthleteTaskDetailScreen> createState() =>
      _AthleteTaskDetailScreenState();
}

class _AthleteTaskDetailScreenState extends State<AthleteTaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.activityCubit.selectExistingTask(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.activityCubit,
      child: BlocListener<HeartBleCubit, HeartBleState>(
        listenWhen: (prev, curr) =>
            (prev.heartRate != curr.heartRate && curr.heartRate > 0) ||
            prev.spo2 != curr.spo2 ||
            prev.stressLevel != curr.stressLevel ||
            prev.hrv != curr.hrv,
        listener: (context, bleState) {
          if (bleState.heartRate > 0) {
            widget.activityCubit.recordHeartRate(bleState.heartRate);
          }
          widget.activityCubit.updateBiometrics(
            spo2: bleState.spo2 > 0 ? bleState.spo2.toDouble() : null,
            stressLevel: bleState.stressLevel > 0 ? bleState.stressLevel : null,
            hrv: bleState.hrv > 0 ? bleState.hrv : null,
          );
        },
        child: BlocConsumer<AthleteActivityCubit, AthleteActivityState>(
          listenWhen: (prev, curr) =>
              prev.isSessionActive != curr.isSessionActive &&
              !curr.isSessionActive,
          listener: (context, state) {
            // Session khatam ho gayi — wapas task list pe jaao
            if (mounted) context.pop();
          },
          builder: (context, state) {
            final isActive = state.isSessionActive;

            return Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                title: Text(isActive ? 'Active Session' : widget.task.name),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: isActive
                    ? const SizedBox.shrink()
                    : BackButton(
                        onPressed: () {
                          widget.activityCubit.cancelPendingTask();
                          context.pop();
                        },
                      ),
              ),
              body: isActive
                  ? ActiveSessionView(state: state)
                  : PendingTaskView(state: state),
            );
          },
        ),
      ),
    );
  }
}
