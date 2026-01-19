import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ScanStatus { idle, scanning }

class BluetoothScanState {
  final ScanStatus status;
  final List<ScanResult> devices;

  const BluetoothScanState({
    required this.status,
    required this.devices,
  });

  factory BluetoothScanState.initial() {
    return const BluetoothScanState(
      status: ScanStatus.idle,
      devices: [],
    );
  }

  BluetoothScanState copyWith({
    ScanStatus? status,
    List<ScanResult>? devices,
  }) {
    return BluetoothScanState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
    );
  }
}
