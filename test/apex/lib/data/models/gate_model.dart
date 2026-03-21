import 'package:equatable/equatable.dart';

enum GateType { master, slave, intermediate }

enum GateSignalQuality { excellent, good, weak, offline }

class GateModel extends Equatable {
  final String deviceId;   // BLE device ID
  final String name;       // "APEX-M01"
  final GateType type;
  final double distanceMeters; // 0.0 for master
  final int signalDbm;         // -42
  final bool isConnected;

  const GateModel({
    required this.deviceId,
    required this.name,
    required this.type,
    this.distanceMeters = 0.0,
    this.signalDbm = 0,
    this.isConnected = false,
  });

  bool get isMaster => type == GateType.master;
  bool get isSlave => type == GateType.slave;

  GateSignalQuality get signalQuality {
    if (!isConnected) return GateSignalQuality.offline;
    if (signalDbm >= -60) return GateSignalQuality.excellent;
    if (signalDbm >= -70) return GateSignalQuality.good;
    if (signalDbm >= -80) return GateSignalQuality.weak;
    return GateSignalQuality.offline;
  }

  String get signalLabel {
    switch (signalQuality) {
      case GateSignalQuality.excellent: return 'LIVE';
      case GateSignalQuality.good:      return 'OK';
      case GateSignalQuality.weak:      return 'WEAK';
      case GateSignalQuality.offline:   return 'OFFLINE';
    }
  }

  GateModel copyWith({
    String? deviceId,
    String? name,
    GateType? type,
    double? distanceMeters,
    int? signalDbm,
    bool? isConnected,
  }) {
    return GateModel(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      signalDbm: signalDbm ?? this.signalDbm,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  // Mock gates for development
  static GateModel mockMaster() => const GateModel(
    deviceId: 'mock-master-001',
    name: 'APEX-M01',
    type: GateType.master,
    distanceMeters: 0.0,
    signalDbm: -42,
    isConnected: true,
  );

  static GateModel mockSlave(double distance) => GateModel(
    deviceId: 'mock-slave-001',
    name: 'APEX-S01',
    type: GateType.slave,
    distanceMeters: distance,
    signalDbm: -67,
    isConnected: true,
  );

  @override
  List<Object?> get props => [deviceId, name, type, distanceMeters, signalDbm, isConnected];
}
