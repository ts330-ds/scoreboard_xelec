import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/my_tasks_state.dart';

class MyTasksListView extends StatefulWidget {
  final void Function(AthleteTaskEntity task) onTaskTap;

  const MyTasksListView({super.key, required this.onTaskTap});

  @override
  State<MyTasksListView> createState() => _MyTasksListViewState();
}

class _MyTasksListViewState extends State<MyTasksListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MyTasksCubit>().loadMore();
    }
  }

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
    if (state.status == MyTasksStatus.initial ||
        state.status == MyTasksStatus.loading) {
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
                Icon(
                  state.isAuthError ? Icons.lock_outline : Icons.error_outline,
                  color: AppColors.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Something went wrong',
                  style: const TextStyle(color: AppColors.subtext, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (state.isAuthError)
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.login),
                    label: const Text('Login again'),
                  )
                else
                  TextButton.icon(
                    onPressed: () => context.read<MyTasksCubit>().fetchTasks(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
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
                  'No tasks found',
                  style: TextStyle(color: AppColors.subtext, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap the + button to create a new task',
                  style: TextStyle(color: AppColors.subtext, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final count = state.tasks.length;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      // +1 for the bottom loader while the next page is being fetched.
      itemCount: count + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= count) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _TaskCard(task: state.tasks[index], onTap: widget.onTaskTap);
      },
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
                  Builder(builder: (_) {
                    final isPending =
                        task.status?.toLowerCase() == 'pending';
                    final durMin = int.tryParse(task.duration) ?? 0;
                    final showDuration = !isPending && durMin > 0;
                    final showAssignedBy = task.assignedByName != null &&
                        task.assignedBy != 'self';
                    if (!showDuration && !showAssignedBy) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (showDuration) ...[
                            const Icon(Icons.timer_outlined,
                                size: 13, color: AppColors.subtext),
                            const SizedBox(width: 4),
                            Text(
                              '$durMin min',
                              style: const TextStyle(
                                  color: AppColors.subtext, fontSize: 12),
                            ),
                          ],
                          if (showAssignedBy) ...[
                            if (showDuration) const SizedBox(width: 10),
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
                    );
                  }),
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
