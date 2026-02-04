import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../common_widget/controller_heading.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../../utility/universal_method.dart';
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
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
                            ? () => context.read<ArcheryTimerCubit>().startCycle()
                            : null,
                      ),
                      _buildControlButton(
                        icon: timerState.isPaused ? Icons.play_arrow : Icons.pause,
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
                            ? () => context.read<ArcheryTimerCubit>().stopTimer()
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // End Info
                  Text(
                    'End ${controllerState.currentEndNumber} of ${controllerState.totalEnds}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

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
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      context.read<ArcheryTimerCubit>().stopTimer();
                      context.read<ArcheryControllerCubit>().showIdleScreen();
                    },
                    icon: const Icon(Icons.home, color: Colors.grey),
                    label: const Text(
                      'Back to Idle',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const ControllerHeading(text: "Display Settings"),
                  widgetGap(),
                  BlocSelector<ArcheryControllerCubit, ArcheryControllerState, int>(
                    selector: (state) => state.brightness,
                    builder: (context, brightness) {
                      return BrightnessSliderMinimal(
                        value: brightness.toDouble(),
                        onChanged: (value) {
                          context.read<ArcheryControllerCubit>().setTempBrightness(value.toInt());
                        },
                        onChangedEnd: (double value) {
                          context.read<ArcheryControllerCubit>().setBrightness(value.toInt());
                        },
                      );
                    },
                  ),
                  widgetGap(),
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
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}
