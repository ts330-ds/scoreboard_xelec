import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import '../../../../../bluetooth/mapper/handball_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';
import 'kabaddi_timer_state.dart';

class KabaddiTimerCubit extends Cubit<KabaddiTimerState> {
  Timer? _timer;
  final BleService bleService;
  final KabaddiBleMapper ballBleMapper;
  KabaddiTimerCubit({
    int startMinutes = 20,
    required this.bleService,
    required this.ballBleMapper
  })
      : super(KabaddiTimerState.initial(startMinutes: startMinutes));

  /// Start timer
  void start() {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(status: TimerStatus.running));


    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (state.seconds <= 1) {
          timer.cancel();
          emit(
            state.copyWith(
              seconds: 0,
              status: TimerStatus.finished, // timer stopped
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
      },
    );
    bleService.send(ballBleMapper.startTimer());
  }

  /// Pause timer
  void pause() {
    if (state.status != TimerStatus.running) return;

    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
    bleService.send(ballBleMapper.pauseTimer());
  }

  /// Resume timer
  void resume() {
    if (state.status != TimerStatus.paused) return;
    start();
    bleService.send(ballBleMapper.startTimer());
  }

  /// Reset everything
  void reset() {
    _timer?.cancel();
    emit(KabaddiTimerState.initial());
  }

  void setTime(int totalSeconds) {
    _timer?.cancel();
    emit(
      state.copyWith(
        seconds: totalSeconds,
        initialSeconds: totalSeconds,
        status: TimerStatus.initial,
      ),
    );
    //bleService.send(ballBleMapper.setMinutes(totalSeconds));
  }

  /* =======================
   * Cleanup
   * ======================= */
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
