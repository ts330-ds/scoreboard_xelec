import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/screen/session_upload_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/active_session_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/pending_task_view.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/session_feedback_sheet.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

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
  // Guard — async listener dobara fire na ho jab feedback/upload flow chal raha ho.
  bool _handlingSessionEnd = false;

  @override
  void initState() {
    super.initState();
    widget.activityCubit.selectExistingTask(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.activityCubit,
      child: BlocConsumer<AthleteActivityCubit, AthleteActivityState>(
          listenWhen: (prev, curr) =>
              // Session khatam — feedback sheet show karne ka moment.
              (prev.pendingFeedbackTaskId == null &&
                  curr.pendingFeedbackTaskId != null) ||
              // Edge case: session abort ho gayi without taskId (pending wala),
              // tab seedha pop kar do.
              (prev.isSessionActive &&
                  !curr.isSessionActive &&
                  curr.pendingFeedbackTaskId == null),
          listener: (context, state) async {
            final taskId = state.pendingFeedbackTaskId;
            if (taskId == null) {
              if (mounted) context.pop();
              return;
            }

            // Guard — agar pehle se feedback/upload flow chal raha hai to skip.
            if (_handlingSessionEnd) return;
            _handlingSessionEnd = true;

            final sessionStart = state.completedSessionStart;
            final sessionEnd = state.completedSessionEnd;
            if (sessionStart == null || sessionEnd == null) {
              _handlingSessionEnd = false;
              if (mounted) context.pop();
              return;
            }

            // Feedback pehle — stop ke turant baad, isi screen pe mandatory form.
            if (!mounted) return;
            await SessionFeedbackSheet.show(context, taskId: taskId);

            // Feedback done — ab upload screen pe bhejo.
            final submitCubit = widget.activityCubit
                .createUploadCubit(sl<TaskZipSubmitCubit>());

            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SessionUploadScreen(
                  submitCubit: submitCubit,
                  taskId: taskId,
                  taskName: widget.task.name,
                  sessionStart: sessionStart,
                  sessionEnd: sessionEnd,
                ),
              ),
            );

            // Upload screen pop hua — agar complete nahi hua (user ne skip kiya)
            // to cubit cleanup karo taaki memory leak na ho.
            if (submitCubit.state.status != TaskZipStatus.complete) {
              widget.activityCubit.cleanupUploadCubit(submitCubit);
            }

            widget.activityCubit.acknowledgeFeedbackPrompt();
            _handlingSessionEnd = false;
            if (!mounted) return;
            context.pop();
          },
          builder: (context, state) {
            final isActive = state.isSessionActive;

            // Active session background isolate me chalti hai — back dabane pe
            // session rukti nahi, sirf list pe wapas jaate hain. Activity tab ka
            // "Go to Active Session" banner dobara isi screen pe le aata hai.
            return Scaffold(
              backgroundColor: AppColors.bg,
              appBar: AppBar(
                title: Text(isActive ? 'Active Session' : widget.task.name),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: BackButton(
                  onPressed: () {
                    if (!isActive) widget.activityCubit.cancelPendingTask();
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
    );
  }
}

