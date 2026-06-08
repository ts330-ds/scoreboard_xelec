import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/submit_feedback_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/session_feedback_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/session_feedback_state.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class SessionFeedbackSheet extends StatelessWidget {
  const SessionFeedbackSheet({super.key});

  /// Mandatory feedback sheet — sirf successful Save pe close hoti hai.
  /// Backdrop tap, swipe-down, system back, sab block hain.
  /// Return value hamesha `true` hota hai (success ke baad hi pop hoti hai).
  static Future<bool?> show(BuildContext context, {required int taskId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => BlocProvider(
        create: (_) => SessionFeedbackCubit(
          submitFeedback: sl<SubmitFeedbackUseCase>(),
          taskId: taskId,
        ),
        child: const SessionFeedbackSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionFeedbackCubit, SessionFeedbackState>(
      listenWhen: (prev, curr) =>
          prev.isSubmitted != curr.isSubmitted ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isSubmitted) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SessionFeedbackCubit>();
        return PopScope(
          // System back / back-gesture block — feedback mandatory hai.
          canPop: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Header(
                      onSave: state.isSubmitting ? null : cubit.submit,
                      busy: state.isSubmitting,
                    ),
                    const SizedBox(height: 20),
                    _DifficultyCard(
                      value: state.difficulty,
                      onChanged: state.isSubmitting
                          ? (_) {}
                          : cubit.setDifficulty,
                    ),
                    const SizedBox(height: 14),
                    _NotesField(
                      initial: state.notes,
                      enabled: !state.isSubmitting,
                      onChanged: cubit.setNotes,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: AppColors.subtext,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onSave;
  final bool busy;

  const _Header({required this.onSave, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Save activity',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(64, 36),
          ),
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DifficultyCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How hard was it?',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: AppColors.text,
              inactiveTrackColor: AppColors.text,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 11,
                elevation: 2,
              ),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
              activeTickMarkColor: AppColors.text,
              inactiveTickMarkColor: AppColors.text,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text('Extremely easy',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Spacer(),
              Text('Maximal',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final String initial;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _NotesField({
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        minLines: 3,
        maxLines: 6,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Notes',
          hintStyle: TextStyle(color: AppColors.subtext, fontSize: 15),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

