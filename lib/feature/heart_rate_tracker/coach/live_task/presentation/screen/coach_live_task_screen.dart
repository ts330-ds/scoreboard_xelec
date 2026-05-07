import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/coach_live_task_cubit.dart';
import '../layout/coach_live_task_mobile.dart';

class CoachLiveTaskScreen extends StatelessWidget {
  final int taskId;
  final String athleteName;
  final String taskName;

  const CoachLiveTaskScreen({
    super.key,
    required this.taskId,
    required this.athleteName,
    required this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoachLiveTaskCubit>()..startWatching(taskId),
      child: CoachLiveTaskMobile(
        taskId: taskId,
        athleteName: athleteName,
        taskName: taskName,
      ),
    );
  }
}
