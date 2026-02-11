import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_state.dart';

import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../common_widget/controller_heading.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../bluetooth/service/ble_service.dart';
import '../cubit/controller/archery_controller_cubit.dart';
import '../cubit/timer/archery_timer_cubit.dart';

class ArcheryControlPanel extends StatelessWidget {
  const ArcheryControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryTimerCubit, ArcheryTimerState>(
      builder: (context, timerState) {
        return BlocBuilder<ArcheryControllerCubit, ArcheryControllerState>(
          builder: (context, controllerState) {
            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.play_arrow,
                        label: 'START',
                        color: Colors.green,
                        onPressed: timerState.phase == TimerPhase.stopped
                            ? () =>
                                  context.read<ArcheryTimerCubit>().startCycle()
                            : null,
                      ),
                      _buildControlButton(
                        icon: timerState.isPaused
                            ? Icons.play_arrow
                            : Icons.pause,
                        label: timerState.isPaused ? 'RESUME' : 'PAUSE',
                        color: Colors.orange,
                        onPressed: timerState.isRunning || timerState.isPaused
                            ? () {
                                final cubit = context.read<ArcheryTimerCubit>();
                                timerState.isPaused
                                    ? cubit.resumeTimer()
                                    : cubit.pauseTimer();
                              }
                            : null,
                      ),
                      _buildControlButton(
                        icon: Icons.stop,
                        label: 'STOP',
                        color: Colors.red,
                        onPressed: timerState.phase != TimerPhase.stopped
                            ? () =>
                                  context.read<ArcheryTimerCubit>().stopTimer()
                            : null,
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // End Info
                  Text(
                    'End ${controllerState.currentEndNumber} of ${controllerState.totalEnds}',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  ),

                  SizedBox(height: 8.h),

                  // Skip Practice Button
                  if (controllerState.matchPhase == MatchPhase.sighter)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ArcheryTimerCubit>().stopTimer();
                        context.read<ArcheryControllerCubit>().skipPractice();
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('SKIP SIGHTER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),

                  // Back to Idle
                  SizedBox(height: 8.h),
                  

                   ControllerHeading(
                    text: "Display Settings",
                    style: TextStyle(color: Colors.white,fontSize: 16.sp),
                  ),
                  SizedBox(height: 16.h),
                  BlocSelector<
                    ArcheryControllerCubit,
                    ArcheryControllerState,
                    int
                  >(
                    selector: (state) => state.setTempBrightness,
                    builder: (context, brightness) {
                      return BrightnessSliderMinimal(
                        value: brightness.toDouble(),
                        onChanged: (value) {
                          context
                              .read<ArcheryControllerCubit>()
                              .setTempBrightness(value.toInt());
                        },
                        onChangedEnd: (value) {
                          context.read<ArcheryControllerCubit>().setBrightness(
                            value.toInt(),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BuzzerButton(bleService: sl<BleService>()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? color : Colors.grey,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(16.w),
          ),
          child: Icon(icon, size: 28.sp, color: Colors.white),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 11.sp),
        ),
      ],
    );
  }
}
