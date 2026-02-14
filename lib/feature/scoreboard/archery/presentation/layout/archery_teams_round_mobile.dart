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

import '../cubit/teams_cubit/timer/archery_team_timer_cubit.dart';
import '../cubit/teams_cubit/timer/archery_team_timer_state.dart';

class ArcheryTeamsRoundMobile extends StatelessWidget {
  const ArcheryTeamsRoundMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreFontSize = 56.sp;
    final circleSize = 57.6.w;
    final arrowSize = 43.2.sp;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.pop();
      },
      child: AdaptiveScaffold(
        title: 'Team Round',
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
                      'TEAM ARCHERY',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  BlocBuilder<ArcheryTeamTimerCubit, ArcheryTeamTimerState>(
                    builder: (context, timerState) {
                      final value = timerState.seconds
                          .clamp(0, 999)
                          .toString()
                          .padLeft(3, '0');
                      final isPrestart =
                          timerState.phase == ArcheryTeamTimerPhase.prestart;
                      final timeColor = isPrestart
                          ? Colors.red
                          : timerState.seconds <= 30
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
                  BlocBuilder<ArcheryTeamTimerCubit, ArcheryTeamTimerState>(
                    builder: (context, timerState) {
                      final isLeft =
                          timerState.activeSide == ArcheryTeamSide.left;
                      final isRight =
                          timerState.activeSide == ArcheryTeamSide.right;
                      final isPrestart =
                          timerState.phase == ArcheryTeamTimerPhase.prestart;
                      final leftCircleColor = Colors.red;
                      final rightCircleColor = timerState.seconds <= 30
                          ? Colors.orange
                          : Colors.green;

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
                              Icon(
                                Icons.arrow_back_rounded,
                                size: arrowSize,
                                color: isLeft
                                    ? Colors.green
                                    : Colors.grey.shade600,
                              ),
                              SizedBox(width: 14.4.w),
                              Text(
                                timerState.isComplete
                                    ? 'END'
                                    : '${timerState.currentRound}/${timerState.totalRounds}',
                                style: TextStyle(
                                  fontSize: scoreFontSize * 0.3,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 4.sp,
                                ),
                              ),
                              SizedBox(width: 14.4.w),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: arrowSize,
                                color: isRight
                                    ? Colors.green
                                    : Colors.grey.shade600,
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
                        const Text(
                          'CONTROLLER',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        BlocBuilder<
                          ArcheryTeamTimerCubit,
                          ArcheryTeamTimerState
                        >(
                          builder: (context, timerState) {
                            final isRunning =
                                timerState.status ==
                                ArcheryTeamTimerStatus.running;
                            final isPaused =
                                timerState.status ==
                                ArcheryTeamTimerStatus.paused;
                            final isComplete = timerState.isComplete;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ControlButton(
                                  label: 'START',
                                  icon: Icons.play_arrow,
                                  color: Colors.black,
                                  enabled: !isRunning && !isComplete,
                                  onTap: () => context
                                      .read<ArcheryTeamTimerCubit>()
                                      .start(),
                                ),
                                SizedBox(width: 6.w),
                                if (isPaused)
                                  _ControlButton(
                                    label: 'RESUME',
                                    icon: Icons.play_arrow,
                                    color: Colors.black,
                                    enabled: isPaused && !isComplete,
                                    onTap: () => context
                                        .read<ArcheryTeamTimerCubit>()
                                        .resume(),
                                  )
                                else
                                  _ControlButton(
                                    label: 'PAUSE',
                                    icon: Icons.pause,
                                    color: Colors.black,
                                    enabled:
                                        isRunning && !isPaused && !isComplete,
                                    onTap: () => context
                                        .read<ArcheryTeamTimerCubit>()
                                        .pause(),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 20.h),
                        BlocBuilder<
                          ArcheryTeamTimerCubit,
                          ArcheryTeamTimerState
                        >(
                          builder: (context, timerState) {
                            final isLeft =
                                timerState.activeSide == ArcheryTeamSide.left;
                            final isRight =
                                timerState.activeSide == ArcheryTeamSide.right;
                            final isComplete = timerState.isComplete;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SideSelectButton(
                                  label: 'LEFT TEAM',
                                  icon: Icons.arrow_back_rounded,
                                  color: Colors.black,
                                  selected: isLeft,
                                  enabled: !isComplete && !isLeft,
                                  onTap: () => context
                                      .read<ArcheryTeamTimerCubit>()
                                      .switchSide(ArcheryTeamSide.left),
                                ),
                                SizedBox(width: 12.w),
                                _SideSelectButton(
                                  label: 'RIGHT TEAM',
                                  icon: Icons.arrow_forward_rounded,
                                  color: Colors.black,
                                  selected: isRight,
                                  enabled: !isComplete && !isRight,
                                  onTap: () => context
                                      .read<ArcheryTeamTimerCubit>()
                                      .switchSide(ArcheryTeamSide.right),
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
                  BlocSelector<
                    ArcheryTeamTimerCubit,
                    ArcheryTeamTimerState,
                    int
                  >(
                    selector: (state) => state.tempBrightness,
                    builder: (context, brightness) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: BrightnessSliderMinimal(
                          value: brightness.toDouble(),
                          onChanged: (value) {
                            context
                                .read<ArcheryTeamTimerCubit>()
                                .setTempBrightness(value.toInt());
                          },
                          onChangedEnd: (value) {
                            context.read<ArcheryTeamTimerCubit>().setBrightness(
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
            color: color.withValues(alpha: 0.35),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.08) : Colors.black12,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: enabled ? color : Colors.black26,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? color : Colors.black38, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.black38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideSelectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  const _SideSelectButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.black12,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: enabled
                ? (selected ? color : Colors.black26)
                : Colors.black26,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? color : Colors.black38, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.black : Colors.black38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
