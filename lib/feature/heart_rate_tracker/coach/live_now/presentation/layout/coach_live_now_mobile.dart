import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_task/presentation/screen/coach_live_task_screen.dart';
import '../cubit/coach_live_now_cubit.dart';
import '../cubit/coach_live_now_state.dart';

class CoachLiveNowMobile extends StatefulWidget {
  const CoachLiveNowMobile({super.key});

  @override
  State<CoachLiveNowMobile> createState() => _CoachLiveNowMobileState();
}

class _CoachLiveNowMobileState extends State<CoachLiveNowMobile> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CoachLiveNowCubit>().loadActiveTasks(status: 'in_progress');

    // When user scrolls near the bottom → trigger loadMore
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200) {
        context.read<CoachLiveNowCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openTask(ActiveTaskEntity task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachLiveTaskScreen(
          taskId: task.taskId,
          athleteName: task.athleteName,
          taskName: task.taskName,
        ),
      ),
    );
    if (mounted) {
      context
          .read<CoachLiveNowCubit>()
          .loadActiveTasks(status: 'in_progress');
    }
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
                        status: 'in_progress',
                      ),
            ),
          ),
        ],
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
                    status: 'in_progress',
                  ),
            );
          }

          if (state.tasks.isEmpty) {
            return const _EmptyView();
          }

          // Bug-guard: if the loaded page doesn't fill the viewport there's
          // nothing to scroll, so the scroll listener would never fire
          // loadMore. After layout, fetch the next page if there are more
          // records but the list isn't scrollable yet.
          if (state.hasMore &&
              state.status != CoachLiveNowStatus.loadingMore &&
              state.loadMoreError == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_scrollController.hasClients) return;
              if (_scrollController.position.maxScrollExtent <= 0) {
                context.read<CoachLiveNowCubit>().loadMore();
              }
            });
          }

          final isLoadingMore =
              state.status == CoachLiveNowStatus.loadingMore;
          final hasFooter = isLoadingMore || state.loadMoreError != null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<CoachLiveNowCubit>().loadActiveTasks(
                  status: 'in_progress',
                ),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length + (hasFooter ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == state.tasks.length) {
                  if (state.loadMoreError != null) {
                    return _LoadMoreError(
                      message: state.loadMoreError!,
                      onRetry: () =>
                          context.read<CoachLiveNowCubit>().retryLoadMore(),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                return _ActiveTaskCard(
                  task: state.tasks[index],
                  onTap: () => _openTask(state.tasks[index]),
                );
              },
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

// ── Inline "load more failed" footer with retry ───────────────────────────────

class _LoadMoreError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadMoreError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subtext, fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
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
