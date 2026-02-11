import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_scan_state.dart';

class BluetoothScanCubit extends Cubit<BluetoothScanState> {
  BluetoothScanCubit() : super(BluetoothScanState.initial());

  StreamSubscription? _sub;
  Timer? _timeoutTimer;
  static const Duration _scanTimeout = Duration(seconds: 8);

  Future<void> startScan() async {
    await _sub?.cancel();
    _timeoutTimer?.cancel();
    emit(state.copyWith(status: ScanStatus.scanning, devices: []));

    await FlutterBluePlus.startScan(timeout: _scanTimeout);

    _sub = FlutterBluePlus.scanResults.listen((results) {
      emit(state.copyWith(devices: results));
    });

    _timeoutTimer = Timer(_scanTimeout, () {
      stopScan();
    });
  }

  Future<void> stopScan() async {
    _timeoutTimer?.cancel();
    await FlutterBluePlus.stopScan();
    await _sub?.cancel();
    emit(state.copyWith(status: ScanStatus.idle));
  }

  @override
  Future<void> close() {
    _timeoutTimer?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
