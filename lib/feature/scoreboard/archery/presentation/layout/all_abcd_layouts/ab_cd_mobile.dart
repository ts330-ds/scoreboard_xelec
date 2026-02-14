import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/common_widget/brightness_slider_widget.dart';
import 'package:xelex_esp/common_widget/buzzerWidget.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../../cubit/ab_cd_cubit/ab_cd_timer_cubit.dart';
import '../../cubit/ab_cd_cubit/ab_cd_timer_state.dart';

class AB_CDMobile extends StatelessWidget {
  const AB_CDMobile({super.key});

  Future<bool?> _showExitDialog(BuildContext context) {
    final timerCubit = sl<Ab_CdTimerCubit>();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text(
          'Are you sure you want to close the scoreboard? Any unsaved progress may be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              timerCubit.resetAll();
              Navigator.of(context).pop(true);
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreFontSize = 56.sp;
    final circleSize = 57.6.w;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context) ?? false;
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: BlocProvider.value(
        value: sl<Ab_CdTimerCubit>(),
        child: AdaptiveScaffold(
          title: 'AB-CD Mode',
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AB-CD ARCHERY',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    BlocBuilder<Ab_CdTimerCubit, AbCdTimerState>(
                      builder: (context, state) {
                        final value = state.seconds
                            .clamp(0, 999)
                            .toString()
                            .padLeft(3, '0');
                        final isPrestart =
                            state.phase == AbCdTimerPhase.prestart;
                        final timeColor = isPrestart
                            ? Colors.red
                            : state.seconds <= 30
                            ? Colors.orange
                            : Colors.green;

                        return SizedBox(
                          width: 1.sw,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: scoreFontSize,
                                fontWeight: FontWeight.bold,
                                color: timeColor,
                                letterSpacing: 2.sp,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                    BlocBuilder<Ab_CdTimerCubit, AbCdTimerState>(
                      builder: (context, state) {
                        final isPrestart =
                            state.phase == AbCdTimerPhase.prestart;
                        final leftCircleColor = Colors.red;
                        final rightCircleColor = state.seconds <= 30
                            ? Colors.orange
                            : Colors.green;
                        final isSighter =
                            state.roundPhase == AbCdRoundPhase.sighter;
                        final phaseLabel = isSighter ? 'SIGHTER' : 'SCORING';
                        final currentRound = state.currentRoundNumber;
                        final totalRounds = isSighter
                            ? state.totalSighterRounds
                            : state.totalScoringRounds;
                        final teamLabel = state.currentTeam == AbCdTeam.ab
                            ? 'AB'
                            : 'CD';

                        return SizedBox(
                          width: 1.sw,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Opacity(
                                  opacity: isPrestart ? 1 : 0,
                                  child: _ScoreCircle(
                                    size: circleSize,
                                    color: leftCircleColor,
                                  ),
                                ),
                                SizedBox(width: 21.6.w),
                                Column(
                                  children: [
                                    Text(
                                      state.isComplete
                                          ? 'END'
                                          : 'Team $teamLabel',
                                      style: TextStyle(
                                        fontSize: scoreFontSize * 0.28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: 3.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '$phaseLabel  $currentRound/$totalRounds',
                                      style: TextStyle(
                                        fontSize: scoreFontSize * 0.22,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        letterSpacing: 2.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 21.6.w),
                                Opacity(
                                  opacity: isPrestart ? 0 : 1,
                                  child: _ScoreCircle(
                                    size: circleSize,
                                    color: rightCircleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 40.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          const ControllerHeading(text: 'CONTROLLER'),
                          SizedBox(height: 16.h),
                          BlocBuilder<Ab_CdTimerCubit, AbCdTimerState>(
                            builder: (context, state) {
                              final isSighterAvailable =
                                  state.totalSighterRounds > 0;
                              final isSighterSelected =
                                  state.roundPhase == AbCdRoundPhase.sighter;
                              final isScoringSelected =
                                  state.roundPhase == AbCdRoundPhase.scoring;

                              return Column(
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8.w,
                                    runSpacing: 8.h,
                                    children: [
                                      _ControlButton(
                                        label: 'Select Sighter',
                                        icon: isSighterSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSighterSelected
                                            ? Colors.black
                                            : Colors.black54,
                                        enabled: isSighterAvailable,
                                        onTap: () => context
                                            .read<Ab_CdTimerCubit>()
                                            .setSelectedRoundPhase(
                                              AbCdRoundPhase.sighter,
                                            ),
                                      ),
                                      _ControlButton(
                                        label: 'Select Scoring',
                                        icon: isScoringSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isScoringSelected
                                            ? Colors.black
                                            : Colors.black54,
                                        onTap: () => context
                                            .read<Ab_CdTimerCubit>()
                                            .setSelectedRoundPhase(
                                              AbCdRoundPhase.scoring,
                                            ),
                                      ),
                                      BlocBuilder<
                                        Ab_CdTimerCubit,
                                        AbCdTimerState
                                      >(
                                        builder: (context, state) {
                                          final teamLabel =
                                              state.currentTeam == AbCdTeam.ab
                                              ? 'AB'
                                              : 'CD';
                                          final nextTeamLabel =
                                              state.currentTeam == AbCdTeam.ab
                                              ? 'CD'
                                              : 'AB';
                                          return _ControlButton(
                                            label: 'Switch to $nextTeamLabel',
                                            icon: Icons.swap_horiz,
                                            color: Colors.black,
                                            onTap: () => context
                                                .read<Ab_CdTimerCubit>()
                                                .toggleTeam(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  if (isSighterSelected && isSighterAvailable)
                                    _StepperControl(
                                      label: 'SIGHTER ROUND',
                                      valueText:
                                          '${state.currentSighterRound}/${state.totalSighterRounds}',
                                      onDecrement: () => context
                                          .read<Ab_CdTimerCubit>()
                                          .decrementCurrentSighterRound(),
                                      onIncrement: () => context
                                          .read<Ab_CdTimerCubit>()
                                          .incrementCurrentSighterRound(),
                                    ),
                                  if (isScoringSelected)
                                    _StepperControl(
                                      label: 'SCORING ROUND',
                                      valueText:
                                          '${state.currentScoringRound}/${state.totalScoringRounds}',
                                      onDecrement: () => context
                                          .read<Ab_CdTimerCubit>()
                                          .decrementCurrentScoringRound(),
                                      onIncrement: () => context
                                          .read<Ab_CdTimerCubit>()
                                          .incrementCurrentScoringRound(),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 16.h),
                          BlocBuilder<Ab_CdTimerCubit, AbCdTimerState>(
                            builder: (context, state) {
                              final isRunning =
                                  state.status == AbCdTimerStatus.running;
                              final isPaused =
                                  state.status == AbCdTimerStatus.paused;
                              final isComplete = state.isComplete;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _ControlButton(
                                    label: 'START',
                                    icon: Icons.play_arrow,
                                    color: Colors.black,
                                    enabled: !isRunning && !isComplete,
                                    onTap: () =>
                                        context.read<Ab_CdTimerCubit>().start(),
                                  ),
                                  SizedBox(width: 6.w),
                                  if (isPaused)
                                    Row(
                                      children: [
                                        _ControlButton(
                                          label: 'RESUME',
                                          icon: Icons.play_arrow,
                                          color: Colors.black,
                                          enabled: isPaused && !isComplete,
                                          onTap: () => context
                                              .read<Ab_CdTimerCubit>()
                                              .resume(),
                                        ),
                                        SizedBox(width: 6.w),
                                        _ControlButton(
                                          label: 'RESET',
                                          icon: Icons.refresh,
                                          color: Colors.black,
                                          enabled: !isComplete,
                                          onTap: () => context
                                              .read<Ab_CdTimerCubit>()
                                              .reset(),
                                        ),
                                      ],
                                    )
                                  else
                                    _ControlButton(
                                      label: 'PAUSE',
                                      icon: Icons.pause,
                                      color: Colors.black,
                                      enabled:
                                          isRunning && !isPaused && !isComplete,
                                      onTap: () => context
                                          .read<Ab_CdTimerCubit>()
                                          .pause(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const ControllerHeading(text: 'Display Settings'),
                    SizedBox(height: 8.h),
                    BlocSelector<Ab_CdTimerCubit, AbCdTimerState, int>(
                      selector: (state) => state.tempBrightness,
                      builder: (context, brightness) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: BrightnessSliderMinimal(
                            value: brightness.toDouble(),
                            onChanged: (value) {
                              context.read<Ab_CdTimerCubit>().setTempBrightness(
                                value.toInt(),
                              );
                            },
                            onChangedEnd: (value) {
                              context.read<Ab_CdTimerCubit>().setBrightness(
                                value.toInt(),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BuzzerButton(bleService: sl<BleService>()),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _StepperControl({
    required this.label,
    required this.valueText,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final hasControls = onDecrement != null && onIncrement != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.black12, width: 1.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.sp,
              ),
            ),
          ),
          if (hasControls) ...[
            _IconStepButton(icon: Icons.remove, onTap: onDecrement!),
            SizedBox(width: 8.w),
          ],
          Text(
            valueText,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
          if (hasControls) ...[
            SizedBox(width: 8.w),
            _IconStepButton(icon: Icons.add, onTap: onIncrement!),
          ],
        ],
      ),
    );
  }
}

class _IconStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.w),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(color: Colors.black26),
        ),
        child: Icon(icon, size: 16.sp),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _ScoreCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black, width: size * 0.06),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: size * 0.18,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.08) : Colors.black12,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(
            color: enabled ? color : Colors.black26,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? color : Colors.black38, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.black38,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                letterSpacing: 0.5.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
