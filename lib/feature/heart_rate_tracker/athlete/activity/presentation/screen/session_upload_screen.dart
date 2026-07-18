import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_state.dart';

/// Full-screen overlay shown after session ends.
///
/// Flow:
///   1. Fetching data from BLE device
///   2. Compressing with gzip
///   3. Uploading to server (single request)
///   4. Polling job status
///   5. Complete → pops back; main screen handles feedback sheet
///
/// User cannot dismiss this screen while work is in progress.
class SessionUploadScreen extends StatefulWidget {
  final TaskZipSubmitCubit submitCubit;
  final int taskId;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  /// Task ka naam — top info card me dikhta hai ("ye task hai"). Recovery/
  /// feedback path (jahan sirf taskId hota hai) se null aata hai; tab card
  /// `Session #id` fallback dikhata hai.
  final String? taskName;

  const SessionUploadScreen({
    super.key,
    required this.submitCubit,
    required this.taskId,
    required this.sessionStart,
    required this.sessionEnd,
    this.taskName,
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
    return BlocConsumer<TaskZipSubmitCubit, TaskZipSubmitState>(
      bloc: widget.submitCubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TaskZipStatus.complete) {
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
                          const SizedBox(height: 20),

                          _TaskInfoCard(
                            taskName: widget.taskName,
                            taskId: widget.taskId,
                            sessionStart: widget.sessionStart,
                            sessionEnd: widget.sessionEnd,
                          ),

                          const SizedBox(height: 28),

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

                          if (state.status == TaskZipStatus.fetching)
                            const _WorkingIndicator(
                              icon: Icons.bluetooth_searching,
                              label: 'Communicating with device...',
                            ),

                          if (state.status == TaskZipStatus.compressing)
                            const _WorkingIndicator(
                              icon: Icons.compress,
                              label: 'Compressing data...',
                            ),

                          if (state.status == TaskZipStatus.uploading)
                            const _WorkingIndicator(
                              icon: Icons.cloud_upload_outlined,
                              label: 'Sending to server...',
                            ),

                          if (state.status == TaskZipStatus.polling)
                            const _WorkingIndicator(
                              icon: Icons.hourglass_top,
                              label: 'Processing on server...',
                            ),

                          if (state.status == TaskZipStatus.error)
                            _ErrorActions(
                              onRetry: () {
                                widget.submitCubit.retryUpload(
                                  taskId: widget.taskId,
                                  sessionStartMs: widget.sessionStart.millisecondsSinceEpoch,
                                  sessionEndMs: widget.sessionEnd.millisecondsSinceEpoch,
                                );
                              },
                              onSkip: _finishAndPop,
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  if (isWorking)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _StayOnScreenBanner(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleFor(TaskZipStatus status) {
    switch (status) {
      case TaskZipStatus.idle:
        return 'Preparing...';
      case TaskZipStatus.fetching:
        return 'Fetching Session Data';
      case TaskZipStatus.compressing:
        return 'Compressing Data';
      case TaskZipStatus.uploading:
        return 'Uploading to Server';
      case TaskZipStatus.polling:
        return 'Processing on Server';
      case TaskZipStatus.complete:
        return 'Upload Complete!';
      case TaskZipStatus.error:
        return 'Upload Failed';
    }
  }

  String _subtitleFor(TaskZipSubmitState state) {
    switch (state.status) {
      case TaskZipStatus.idle:
        return 'Getting ready...';
      case TaskZipStatus.fetching:
        // Cubit har attempt pe message me "Attempt X of 3 • …" bhejta hai —
        // wahi dikhao taaki user ko pata rahe kaunsi try chal rahi hai.
        return state.message.isNotEmpty
            ? state.message
            : 'Retrieving heart rate data from your device.\nThis may take a moment.';
      case TaskZipStatus.compressing:
        return 'Compressing ${state.totalReadings} readings for upload.';
      case TaskZipStatus.uploading:
        return 'Sending ${state.totalReadings} compressed readings to server.';
      case TaskZipStatus.polling:
        return 'Server is processing your data.\nThis may take a moment.';
      case TaskZipStatus.complete:
        return '${state.totalReadings} readings uploaded successfully.';
      case TaskZipStatus.error:
        return state.errorMessage ?? 'Something went wrong. Please try again.';
    }
  }
}

// ── Task Info Card ─────────────────────────────────────────────────────────
// "Ye task hai aur yha se yha tak chala hai" — task naam + session ka
// from→to range + duration. Upload ke har phase me top pe visible rehta hai.

class _TaskInfoCard extends StatelessWidget {
  final String? taskName;
  final int taskId;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  const _TaskInfoCard({
    required this.taskName,
    required this.taskId,
    required this.sessionStart,
    required this.sessionEnd,
  });

  @override
  Widget build(BuildContext context) {
    final start = sessionStart.toLocal();
    final end = sessionEnd.toLocal();
    final sameDay =
        start.year == end.year && start.month == end.month && start.day == end.day;

    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    final title = (taskName != null && taskName!.trim().isNotEmpty)
        ? taskName!.trim()
        : 'Session #$taskId';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _durationLabel(sessionEnd.difference(sessionStart)),
                      style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          _RangeRow(
            icon: Icons.play_arrow_rounded,
            label: 'Started',
            value: '${timeFmt.format(start)} · ${dateFmt.format(start)}',
          ),
          const SizedBox(height: 10),
          _RangeRow(
            icon: Icons.stop_rounded,
            label: 'Ended',
            value: sameDay
                ? timeFmt.format(end)
                : '${timeFmt.format(end)} · ${dateFmt.format(end)}',
          ),
        ],
      ),
    );
  }

  static String _durationLabel(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Duration —';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return 'Duration ${h}h ${m}m';
    if (m > 0) return 'Duration ${m}m ${s}s';
    return 'Duration ${s}s';
  }
}

class _RangeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RangeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.subtext,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status Icon ────────────────────────────────────────────────────────────

class _StatusIcon extends StatefulWidget {
  final TaskZipStatus status;
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
    final shouldAnimate = widget.status == TaskZipStatus.fetching ||
        widget.status == TaskZipStatus.compressing ||
        widget.status == TaskZipStatus.uploading ||
        widget.status == TaskZipStatus.polling ||
        widget.status == TaskZipStatus.idle;
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
      case TaskZipStatus.idle:
      case TaskZipStatus.fetching:
        icon = Icons.bluetooth_searching;
        color = AppColors.primary;
      case TaskZipStatus.compressing:
        icon = Icons.compress;
        color = AppColors.primary;
      case TaskZipStatus.uploading:
        icon = Icons.cloud_upload_outlined;
        color = AppColors.primary;
      case TaskZipStatus.polling:
        icon = Icons.hourglass_top;
        color = AppColors.primary;
      case TaskZipStatus.complete:
        icon = Icons.check_circle;
        color = AppColors.success;
      case TaskZipStatus.error:
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

// ── Working Indicator ─────────────────────────────────────────────────────

class _WorkingIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WorkingIndicator({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
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

// ── Stay-on-screen Banner ─────────────────────────────────────────────────

class _StayOnScreenBanner extends StatelessWidget {
  const _StayOnScreenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please stay on this screen',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Don\'t close the app, go back, or switch to another app '
            'while your data is being uploaded.',
            style: TextStyle(
              color: AppColors.warning.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
