import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_task/presentation/screen/coach_live_task_screen.dart';
import '../screen/coach_task_result_screen.dart';
import '../cubit/coach_live_now_cubit.dart';
import '../cubit/coach_live_now_state.dart';

class CoachLiveNowMobile extends StatefulWidget {
  const CoachLiveNowMobile({super.key});

  @override
  State<CoachLiveNowMobile> createState() => _CoachLiveNowMobileState();
}

class _CoachLiveNowMobileState extends State<CoachLiveNowMobile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<CoachLiveNowCubit>().loadActiveTasks(status: 'in_progress');

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      context
          .read<CoachLiveNowCubit>()
          .loadActiveTasks(status: _tabs[_tabController.index]);
    });
  }

  Future<void> _openTask(ActiveTaskEntity task) async {
    final Widget screen = task.status == 'completed'
        ? CoachTaskResultScreen(
            taskId: task.taskId,
            athleteName: task.athleteName,
            taskName: task.taskName,
          )
        : CoachLiveTaskScreen(
            taskId: task.taskId,
            athleteName: task.athleteName,
            taskName: task.taskName,
          );

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) {
      context.read<CoachLiveNowCubit>().loadActiveTasks(
            status: _tabs[_tabController.index],
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Live Now'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<CoachLiveNowCubit, CoachLiveNowState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: state.status == CoachLiveNowStatus.loading
                  ? null
                  : () => context.read<CoachLiveNowCubit>().loadActiveTasks(
                        status: _tabs[_tabController.index],
                      ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: BlocBuilder<CoachLiveNowCubit, CoachLiveNowState>(
        builder: (context, state) {
          if (state.status == CoachLiveNowStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == CoachLiveNowStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => context.read<CoachLiveNowCubit>().loadActiveTasks(
                    status: _tabs[_tabController.index],
                  ),
            );
          }

          if (state.tasks.isEmpty) {
            return const _EmptyView();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<CoachLiveNowCubit>().loadActiveTasks(
                  status: _tabs[_tabController.index],
                ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ActiveTaskCard(
                task: state.tasks[index],
                onTap: () => _openTask(state.tasks[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Active Task Card ──────────────────────────────────────────────────────────

class _ActiveTaskCard extends StatelessWidget {
  final ActiveTaskEntity task;
  final VoidCallback onTap;
  const _ActiveTaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ── Live pulse indicator
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.sensors, color: AppColors.success, size: 22),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.athleteName,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.taskName,
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (task.duration != null) ...[
                        const Icon(Icons.timer_outlined,
                            size: 12, color: AppColors.subtext),
                        const SizedBox(width: 3),
                        Text(
                          '${task.duration} min',
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (task.startedAt != null) ...[
                        const Icon(Icons.schedule,
                            size: 12, color: AppColors.subtext),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(task.startedAt!),
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Status badge
            if (task.status == 'in_progress')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.subtext.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.subtext.withOpacity(0.3)),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.subtext, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoString;
    }
  }
}

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_off, color: AppColors.subtext, size: 52),
          SizedBox(height: 16),
          Text(
            'No active session',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'When an athlete starts a session\nit will appear here',
            style: TextStyle(color: AppColors.subtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
