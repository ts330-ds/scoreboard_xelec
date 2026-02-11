import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/common_widget/brightness_slider_widget.dart';
import 'package:xelex_esp/common_widget/buzzerWidget.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_controller/archery_alternate_game_controller_state.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/alternate_game_controller/archery_alternate_game_controller.dart';
import '../cubit/alternate_game_timer/archery_alternate_game_timer_cubit.dart';
import '../cubit/alternate_game_timer/archery_alternate_game_timer_state.dart';

class ArcheryAlternateMobile extends StatelessWidget {
  const ArcheryAlternateMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreFontSize = 56.sp;
    final circleSize = 57.6.w;
    final arrowSize = 43.2.sp;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ArcheryAlternateGameTimerCubit>()),
        BlocProvider.value(value: sl<ArcheryAlternateGameControllerCubit>()),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Archery - Alternate Mode',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        BlocBuilder<
                          ArcheryAlternateGameControllerCubit,
                          ArcheryAlternateGameControllerState
                        >(
                          builder: (context, gameState) {
                            return Text(
                              _formatModeLabel(gameState.gameMode),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            );
                          },
                        ),
                  ),
                  BlocBuilder<
                    ArcheryAlternateGameTimerCubit,
                    ArcheryAlternateGameTimerState
                  >(
                    builder: (context, timerState) {
                      return BlocBuilder<
                        ArcheryAlternateGameControllerCubit,
                        ArcheryAlternateGameControllerState
                      >(
                        builder: (context, gameState) {
                          final value = timerState.seconds
                              .clamp(0, 999)
                              .toString()
                              .padLeft(3, '0');
                          final isPrestart =
                              timerState.phase == AlternateTimerPhase.prestart;
                          final isSimpleMode =
                              gameState.gameMode == ArcheryGameMode.simple;
                          final timeColor = isPrestart
                              ? Colors.red
                              : isSimpleMode
                              ? Colors.green
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
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  BlocBuilder<
                    ArcheryAlternateGameTimerCubit,
                    ArcheryAlternateGameTimerState
                  >(
                    builder: (context, timerState) {
                      return BlocBuilder<
                        ArcheryAlternateGameControllerCubit,
                        ArcheryAlternateGameControllerState
                      >(
                        builder: (context, gameState) {
                          final isLeft =
                              timerState.activeSide ==
                              ArcheryAlternateSide.left;
                          final isRight =
                              timerState.activeSide ==
                              ArcheryAlternateSide.right;

                          final isPrestart =
                              timerState.phase == AlternateTimerPhase.prestart;
                          final baseLeftCircleColor = Colors.red;
                          final isSimpleMode =
                              gameState.gameMode == ArcheryGameMode.simple;
                          final baseRightCircleColor = isSimpleMode
                              ? Colors.green
                              : timerState.seconds <= 30
                              ? Colors.orange
                              : Colors.green;
                          final leftCircleColor = isPrestart
                              ? baseLeftCircleColor
                              : isLeft
                              ? baseLeftCircleColor
                              : baseLeftCircleColor;
                          final rightCircleColor = isRight
                              ? baseRightCircleColor
                              : baseRightCircleColor;

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
                                    gameState.isComplete
                                        ? '--'
                                        : gameState.currentRound.toString(),
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
                      );
                    },
                  ),
                  SizedBox(height: 40.h),
                  BlocListener<
                    ArcheryAlternateGameControllerCubit,
                    ArcheryAlternateGameControllerState
                  >(
                    listenWhen: (previous, current) =>
                        !previous.isComplete && current.isComplete,
                    listener: (context, state) {
                      context.read<ArcheryAlternateGameTimerCubit>().stop();
                    },
                    child: Padding(
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
                            ArcheryAlternateGameTimerCubit,
                            ArcheryAlternateGameTimerState
                          >(
                            builder: (context, timerState) {
                              final isRunning =
                                  timerState.status ==
                                  AlternateTimerStatus.running;
                              final isPaused =
                                  timerState.status ==
                                  AlternateTimerStatus.paused;

                              return BlocBuilder<
                                ArcheryAlternateGameControllerCubit,
                                ArcheryAlternateGameControllerState
                              >(
                                builder: (context, gameState) {
                                  final isComplete = gameState.isComplete;

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _ControlButton(
                                        label: 'START',
                                        icon: Icons.play_arrow,
                                        color: Colors.black,
                                        enabled: !isRunning && !isComplete,
                                        onTap: () => context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
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
                                              .read<
                                                ArcheryAlternateGameTimerCubit
                                              >()
                                              .resume(),
                                        )
                                      else
                                        _ControlButton(
                                          label: 'PAUSE',
                                          icon: Icons.pause,
                                          color: Colors.black,
                                          enabled:
                                              isRunning &&
                                              !isPaused &&
                                              !isComplete,
                                          onTap: () => context
                                              .read<
                                                ArcheryAlternateGameTimerCubit
                                              >()
                                              .pause(),
                                        ),
                                      // SizedBox(width: 6.w),
                                      // _ControlButton(
                                      //   label: 'STOP',
                                      //   icon: Icons.stop,
                                      //   color: Colors.black,
                                      //   enabled:
                                      //       (isRunning || isPaused) &&
                                      //       !isComplete,
                                      //   onTap: () => context
                                      //       .read<
                                      //         ArcheryAlternateGameTimerCubit
                                      //       >()
                                      //       .stop(),
                                      // ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20.h),
                          BlocBuilder<
                            ArcheryAlternateGameControllerCubit,
                            ArcheryAlternateGameControllerState
                          >(
                            builder: (context, gameState) {
                              final isLeft =
                                  gameState.activeSide ==
                                  ArcheryAlternateSide.left;
                              final isRight =
                                  gameState.activeSide ==
                                  ArcheryAlternateSide.right;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SideSelectButton(
                                    label: 'LEFT TEAM',
                                    icon: Icons.arrow_back_rounded,
                                    color: Colors.black,
                                    selected: isLeft,
                                    onTap: () {
                                      if (gameState.gameMode ==
                                          ArcheryGameMode.alternatingFinals) {
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .switchSide(
                                              ArcheryAlternateSide.left,
                                            );
                                      } else if (gameState.activeSide !=
                                          ArcheryAlternateSide.left) {
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .resetForSimpleSideChange();
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .setActiveSide(
                                              ArcheryAlternateSide.left,
                                            );
                                      }
                                      context
                                          .read<
                                            ArcheryAlternateGameControllerCubit
                                          >()
                                          .registerLeftWin();
                                    },
                                  ),
                                  SizedBox(width: 12.w),
                                  _SideSelectButton(
                                    label: 'RIGHT TEAM',
                                    icon: Icons.arrow_forward_rounded,
                                    color: Colors.black,
                                    selected: isRight,
                                    onTap: () {
                                      if (gameState.gameMode ==
                                          ArcheryGameMode.alternatingFinals) {
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .switchSide(
                                              ArcheryAlternateSide.right,
                                            );
                                      } else if (gameState.activeSide !=
                                          ArcheryAlternateSide.right) {
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .resetForSimpleSideChange();
                                        context
                                            .read<
                                              ArcheryAlternateGameTimerCubit
                                            >()
                                            .setActiveSide(
                                              ArcheryAlternateSide.right,
                                            );
                                      }
                                      context
                                          .read<
                                            ArcheryAlternateGameControllerCubit
                                          >()
                                          .registerRightWin();
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const ControllerHeading(text: "Display Settings"),
                  SizedBox(height: 16.h),
                  BlocSelector<
                    ArcheryAlternateGameControllerCubit,
                    ArcheryAlternateGameControllerState,
                    int
                  >(
                    selector: (state) => state.setTempBrightness,
                    builder: (context, brightness) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: BrightnessSliderMinimal(
                          value: brightness.toDouble(),
                          onChanged: (value) {
                            context
                                .read<ArcheryAlternateGameControllerCubit>()
                                .setTempBrightness(value.toInt());
                          },
                          onChangedEnd: (double value) {
                            context
                                .read<ArcheryAlternateGameControllerCubit>()
                                .setBrightness(value.toInt());
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BuzzerButton(bleService: sl<BleService>()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatModeLabel(ArcheryGameMode mode) {
    switch (mode) {
      case ArcheryGameMode.simple:
        return 'SIMPLE ARCHERY';
      case ArcheryGameMode.alternatingFinals:
        return 'ALTERNATING FINALS';
    }
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

  const _SideSelectButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.black12,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: selected ? color : Colors.black26,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
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
