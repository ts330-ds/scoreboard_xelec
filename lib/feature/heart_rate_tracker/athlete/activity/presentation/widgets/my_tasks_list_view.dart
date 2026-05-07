import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_state.dart';

class MyTasksListView extends StatelessWidget {
  final void Function(AthleteTaskEntity task) onTaskTap;

  const MyTasksListView({super.key, required this.onTaskTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyTasksCubit, MyTasksState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<MyTasksCubit>().fetchTasks(),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, MyTasksState state) {
    if (state.status == MyTasksStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == MyTasksStatus.error) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Kuch galat hua',
                  style: const TextStyle(color: AppColors.subtext, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.read<MyTasksCubit>().fetchTasks(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Dobara try karein'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.status == MyTasksStatus.loaded && state.tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 52, color: AppColors.subtext),
                SizedBox(height: 12),
                Text(
                  'Koi task nahi mila',
                  style: TextStyle(color: AppColors.subtext, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Naya task banane ke liye + button dabaein',
                  style: TextStyle(color: AppColors.subtext, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _TaskCard(task: state.tasks[index], onTap: onTaskTap),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final AthleteTaskEntity task;
  final void Function(AthleteTaskEntity) onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final isCompleted = task.status?.toLowerCase() == 'completed';

    return Opacity(
      opacity: isCompleted ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: () => onTap(task),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_run_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AppColors.subtext),
                      const SizedBox(width: 4),
                      Text(
                        '${task.duration} min',
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 12),
                      ),
                      if (task.assignedByName != null &&
                          task.assignedBy != 'self') ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline,
                            size: 13, color: AppColors.subtext),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedByName!,
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (task.assignedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(task.assignedAt!),
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (task.status != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.status!,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.subtext, size: 20),
          ],
        ),
      ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'active':
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.subtext;
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
