import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_athletes.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_gate_alignment.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_mode_selection.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_results.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_run_test.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_test_config.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/widget/step_test_setup.dart';

class TimingSessionScreen extends StatelessWidget {
  const TimingSessionScreen({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  static const _stepLabels = [
    'Mode',
    'Setup',
    'Athletes',
    'Config',
    'Gates',
    'Run Test',
    'Results',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      buildWhen: (p, c) => p.currentStep != c.currentStep,
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handlePhysicalBack(context, state);
          },
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  _buildStepIndicator(state.currentStep),
                  Expanded(child: _buildCurrentStep(state.currentStep)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Physical back button — navigate to previous step (no accidental full exit).
  void _handlePhysicalBack(BuildContext context, TimingSessionState state) {
    final cubit = context.read<TimingSessionCubit>();
    final step = state.currentStep;

    if (step == 0) {
      // First step — nothing to go back to, do nothing
      return;
    }
    if (step == 5 || step == 6) {
      // Run test / Results — physical back does nothing (use header ✕ to exit)
      return;
    }
    if (step == 4) {
      // Gate step — reset gate state before going back
      cubit.resetGates();
      cubit.prevStep();
      return;
    }
    // Steps 1, 2, 3 — safe to go back
    cubit.prevStep();
  }

  /// Header ✕ button — always shows exit confirmation dialog.
  void _confirmExit(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Exit Session?',
          style: TextStyle(
              color: Color(0xFF1E2A3A), fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'All unsaved progress will be lost.',
          style: TextStyle(color: Color(0xFF6B7A8D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<TimingSessionCubit>().resetSession();
        context.pop();
      }
    });
  }

  Widget _buildHeader(BuildContext context, TimingSessionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _confirmExit(context),
            child: const Icon(Icons.arrow_back_ios_new, color: _text, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Test Session',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _stepLabels[state.currentStep],
                style: const TextStyle(color: _subtext, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / _stepLabels.length,
              backgroundColor: const Color(0xFFE3F2FD),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${currentStep + 1} of ${_stepLabels.length}',
            style: const TextStyle(
              color: _subtext,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(int step) {
    switch (step) {
      case 0:
        return const StepModeSelection();
      case 1:
        return const StepTestSetup();
      case 2:
        return const StepAthletes();
      case 3:
        return const StepTestConfig();
      case 4:
        return const StepGateAlignment();
      case 5:
        return const StepRunTest();
      case 6:
        return const StepResults();
      default:
        return const StepModeSelection();
    }
  }
}
