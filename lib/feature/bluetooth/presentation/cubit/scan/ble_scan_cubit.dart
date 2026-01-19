import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_scan_state.dart';


class BluetoothScanCubit extends Cubit<BluetoothScanState> {
  BluetoothScanCubit() : super(BluetoothScanState.initial());

  StreamSubscription? _sub;

  Future<void> startScan() async {
    emit(state.copyWith(status: ScanStatus.scanning, devices: []));

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
    );

    _sub = FlutterBluePlus.scanResults.listen((results) {
      emit(state.copyWith(devices: results));
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _sub?.cancel();
    emit(state.copyWith(status: ScanStatus.idle));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
