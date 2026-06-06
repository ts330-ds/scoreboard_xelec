import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_result_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_result_submit_state.dart';

/// Full-screen overlay shown after session ends.
///
/// Flow:
///   1. Fetching data from BLE device
///   2. Uploading chunks to server (with progress)
///   3. Complete → pops back; main screen handles feedback sheet
///
/// User cannot dismiss this screen while work is in progress.
class SessionUploadScreen extends StatefulWidget {
  final TaskResultSubmitCubit submitCubit;
  final int taskId;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  const SessionUploadScreen({
    super.key,
    required this.submitCubit,
    required this.taskId,
    required this.sessionStart,
    required this.sessionEnd,
  });

  @override
  State<SessionUploadScreen> createState() => _SessionUploadScreenState();
}

class _SessionUploadScreenState extends State<SessionUploadScreen> {
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    if (!widget.submitCubit.state.isWorking) {
      widget.submitCubit.submitSessionData(
        taskId: widget.taskId,
        sessionStart: widget.sessionStart,
        sessionEnd: widget.sessionEnd,
      );
    }
  }

  Future<void> _showExitWarning() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload in Progress',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: const Text(
          'Your session data is still being uploaded. '
          'Don\'t worry — upload will continue in the background.',
          style: TextStyle(color: AppColors.subtext, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _finishAndPop() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskResultSubmitCubit, TaskResultSubmitState>(
      bloc: widget.submitCubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TaskSubmitStatus.complete) {
          _finishAndPop();
        }
      },
      builder: (context, state) {
        final isWorking = state.isWorking;

        return PopScope(
          canPop: !isWorking,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _showExitWarning();
          },
          child: Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              title: const Text('Session Upload'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: isWorking
                  ? const SizedBox.shrink()
                  : BackButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 48),

                          _StatusIcon(status: state.status),

                          const SizedBox(height: 28),

                          Text(
                            _titleFor(state.status),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _subtitleFor(state),
                            style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          if (state.status == TaskSubmitStatus.uploading)
                            _UploadProgress(state: state),

                          if (state.status == TaskSubmitStatus.fetching)
                            const _FetchingIndicator(),

                          if (state.status == TaskSubmitStatus.error)
                            _ErrorActions(
                              onRetry: () {
                                widget.submitCubit.resumeUpload(widget.taskId);
                              },
                              onSkip: _finishAndPop,
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  if (isWorking)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.warning, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Upload will continue in the background even if you leave.',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleFor(TaskSubmitStatus status) {
    switch (status) {
      case TaskSubmitStatus.idle:
        return 'Preparing...';
      case TaskSubmitStatus.fetching:
        return 'Fetching Session Data';
      case TaskSubmitStatus.uploading:
        return 'Uploading to Server';
      case TaskSubmitStatus.complete:
        return 'Upload Complete!';
      case TaskSubmitStatus.error:
        return 'Upload Failed';
    }
  }

  String _subtitleFor(TaskResultSubmitState state) {
    switch (state.status) {
      case TaskSubmitStatus.idle:
        return 'Getting ready...';
      case TaskSubmitStatus.fetching:
        return 'Retrieving heart rate data from your device.\nThis may take a moment.';
      case TaskSubmitStatus.uploading:
        return 'Sending ${state.totalReadings} readings to server.\nChunk ${state.currentChunk} of ${state.totalChunks}';
      case TaskSubmitStatus.complete:
        return '${state.totalReadings} readings uploaded successfully.';
      case TaskSubmitStatus.error:
        return state.errorMessage ?? 'Something went wrong. Please try again.';
    }
  }
}

// ── Status Icon ────────────────────────────────────────────────────────────

class _StatusIcon extends StatefulWidget {
  final TaskSubmitStatus status;
  const _StatusIcon({required this.status});

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_StatusIcon old) {
    super.didUpdateWidget(old);
    final shouldAnimate = widget.status == TaskSubmitStatus.fetching ||
        widget.status == TaskSubmitStatus.uploading ||
        widget.status == TaskSubmitStatus.idle;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (widget.status) {
      case TaskSubmitStatus.idle:
      case TaskSubmitStatus.fetching:
        icon = Icons.bluetooth_searching;
        color = AppColors.primary;
      case TaskSubmitStatus.uploading:
        icon = Icons.cloud_upload_outlined;
        color = AppColors.primary;
      case TaskSubmitStatus.complete:
        icon = Icons.check_circle;
        color = AppColors.success;
      case TaskSubmitStatus.error:
        icon = Icons.error_outline;
        color = AppColors.error;
    }

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 42),
      ),
    );
  }
}

// ── Upload Progress ────────────────────────────────────────────────────────

class _UploadProgress extends StatelessWidget {
  final TaskResultSubmitState state;
  const _UploadProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chunk ${state.currentChunk} of ${state.totalChunks}',
                style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${state.uploadedReadings} / ${state.totalReadings} readings',
            style: const TextStyle(
              color: AppColors.subtext,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fetching Indicator ─────────────────────────────────────────────────────

class _FetchingIndicator extends StatelessWidget {
  const _FetchingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Communicating with device...',
            style: TextStyle(
              color: AppColors.subtext,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Actions ──────────────────────────────────────────────────────────

class _ErrorActions extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  const _ErrorActions({required this.onRetry, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Retry Upload',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Skip & Continue',
            style: TextStyle(
              color: AppColors.subtext,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
