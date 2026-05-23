import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/my_tasks_list_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/new_activity_sheet.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteActivityMobile extends StatelessWidget {
  const AthleteActivityMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AthleteActivityCubit>()),
        BlocProvider(create: (_) => sl<MyTasksCubit>()..fetchTasks()),
      ],
      child: const _ActivityBody(),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: MyTasksListView(
        onTaskTap: (task) {
          if (task.status?.toLowerCase() == 'completed') {
            context.push(HeartTrackerPaths.athleteTaskResult, extra: task);
            return;
          }

          context.push(
            HeartTrackerPaths.athleteTaskDetail,
            extra: {
              'task': task,
              'activityCubit': context.read<AthleteActivityCubit>(),
            },
          ).then((_) {
            if (context.mounted) context.read<MyTasksCubit>().fetchTasks();
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewActivitySheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showNewActivitySheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AthleteActivityCubit>(),
        child: const NewActivitySheet(),
      ),
    ).then((created) {
      // Sheet sirf tab refetch trigger karega jab task actually create
      // hua ho (success pe pop(true)). Cancel/swipe-down/backdrop pe nahi.
      if (created == true && context.mounted) {
        context.read<MyTasksCubit>().fetchTasks();
      }
    });
  }
}
