import 'package:equatable/equatable.dart';

class TimingGateBleDevice {
  final String name;
  final String uuid;
  final int rssi;

  TimingGateBleDevice({
    required this.name,
    required this.uuid,
    required this.rssi,
  });

  bool get isCompatible {
    final n = name.toUpperCase();
    return n.contains('APEX') || n.contains('GATE') || n.contains('TIMING');
  }

  int get signalBars {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }
}

class TimingGateBleState extends Equatable {
  final String status;
  final List<TimingGateBleDevice> foundDevices;
  final bool isConnected;
  final bool isScanning;
  final bool isConnecting;
  final bool isBluetoothOff;
  final bool isPermissionDenied;
  final String connectedDeviceName;
  final int connectedRssi;

  const TimingGateBleState({
    this.status = 'Disconnected',
    this.foundDevices = const [],
    this.isConnected = false,
    this.isScanning = false,
    this.isConnecting = false,
    this.isBluetoothOff = false,
    this.isPermissionDenied = false,
    this.connectedDeviceName = '',
    this.connectedRssi = 0,
  });

  int get signalBars {
    if (connectedRssi == 0) return 0;
    if (connectedRssi >= -60) return 3;
    if (connectedRssi >= -75) return 2;
    if (connectedRssi >= -90) return 1;
    return 0;
  }

  TimingGateBleState copyWith({
    String? status,
    List<TimingGateBleDevice>? foundDevices,
    bool? isConnected,
    bool? isScanning,
    bool? isConnecting,
    bool? isBluetoothOff,
    bool? isPermissionDenied,
    String? connectedDeviceName,
    int? connectedRssi,
  }) {
    return TimingGateBleState(
      status: status ?? this.status,
      foundDevices: foundDevices ?? this.foundDevices,
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isBluetoothOff: isBluetoothOff ?? this.isBluetoothOff,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedRssi: connectedRssi ?? this.connectedRssi,
    );
  }

  @override
  List<Object?> get props => [
        status,
        foundDevices,
        isConnected,
        isScanning,
        isConnecting,
        isBluetoothOff,
        isPermissionDenied,
        connectedDeviceName,
        connectedRssi,
      ];
}
