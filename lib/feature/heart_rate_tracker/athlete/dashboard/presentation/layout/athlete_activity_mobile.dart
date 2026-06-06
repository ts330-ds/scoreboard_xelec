import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/my_tasks_list_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/new_activity_sheet.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteActivityMobile extends StatelessWidget {
  const AthleteActivityMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BlocProvider.value — cubit singleton hai, dispose pe band nahi hona chahiye
        BlocProvider.value(value: sl<AthleteActivityCubit>()),
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
    return BlocBuilder<AthleteActivityCubit, AthleteActivityState>(
      buildWhen: (prev, curr) =>
          prev.isSessionActive != curr.isSessionActive,
      builder: (context, activityState) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: const Text('My Tasks'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: activityState.isSessionActive
              ? _ActiveSessionBanner(
                  onGoToSession: () => _navigateToActiveSession(context, activityState),
                )
              : MyTasksListView(
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
          floatingActionButton: activityState.isSessionActive
              ? null
              : FloatingActionButton.extended(
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
      },
    );
  }

  void _navigateToActiveSession(BuildContext context, AthleteActivityState activityState) {
    final task = activityState.activeTask;
    if (task == null) return;
    context.push(
      HeartTrackerPaths.athleteTaskDetail,
      extra: {
        'task': task,
        'activityCubit': context.read<AthleteActivityCubit>(),
      },
    );
  }

  void _showNewActivitySheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AthleteActivityCubit>()),
          BlocProvider(create: (_) => sl<SportCubit>()..getSports()),
        ],
        child: const NewActivitySheet(),
      ),
    ).then((created) {
      if (created == true && context.mounted) {
        context.read<MyTasksCubit>().fetchTasks();
      }
    });
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final VoidCallback onGoToSession;
  const _ActiveSessionBanner({required this.onGoToSession});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your task is active now',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have a session in progress. Complete or stop the current session before starting a new task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subtext,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onGoToSession,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text(
                  'Go to Active Session',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
