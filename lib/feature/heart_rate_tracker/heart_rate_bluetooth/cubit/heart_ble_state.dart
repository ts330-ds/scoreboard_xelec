import 'package:equatable/equatable.dart';

class HeartBleDevice {
  final String name;
  final String uuid;
  final int rssi;

  HeartBleDevice({required this.name, required this.uuid, required this.rssi});

  bool get isCompatible {
    final n = name.toUpperCase();
    return n.startsWith('CL') ||
        n.contains('CL800') ||
        n.contains('CL808') ||
        n.contains('HEART') ||
        n.contains('FIT');
  }

  int get signalBars {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }
}

class HeartBleState extends Equatable {
  final String status;
  final List<HeartBleDevice> foundDevices;
  final int heartRate;
  final int battery;
  final bool isConnected;
  final bool isScanning;
  final String lastDevice;

  const HeartBleState({
    this.status = "Disconnected",
    this.foundDevices = const [],
    this.heartRate = 0,
    this.battery = 0,
    this.isConnected = false,
    this.isScanning = false,
    this.lastDevice = "",
  });

  HeartBleState copyWith({
    String? status,
    List<HeartBleDevice>? foundDevices,
    int? heartRate,
    int? battery,
    bool? isConnected,
    bool? isScanning,
    String? lastDevice,
  }) {
    return HeartBleState(
      status: status ?? this.status,
      foundDevices: foundDevices ?? this.foundDevices,
      heartRate: heartRate ?? this.heartRate,
      battery: battery ?? this.battery,
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      lastDevice: lastDevice ?? this.lastDevice,
    );
  }

  @override
  List<Object> get props => [
    status,
    foundDevices,
    heartRate,
    battery,
    isConnected,
    isScanning,
    lastDevice,
  ];
}
