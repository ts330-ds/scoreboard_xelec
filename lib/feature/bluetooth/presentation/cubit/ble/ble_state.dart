import 'package:equatable/equatable.dart';

enum BleStatus { idle, connecting, connected, error }

class BleState extends Equatable {
  final BleStatus status;
  final String? deviceName;
  final String? deviceId;
  final int? rssi;
  final String? error;
  final List<Map<String, String>> previousDevices;

  const BleState({
    required this.status,
    this.deviceName,
    this.deviceId,
    this.rssi,
    this.error,
    this.previousDevices = const [],
  });

  factory BleState.idle({List<Map<String, String>> previousDevices = const []}) =>
      BleState(status: BleStatus.idle, previousDevices: previousDevices);

  factory BleState.connecting({List<Map<String, String>> previousDevices = const []}) =>
      BleState(status: BleStatus.connecting, previousDevices: previousDevices);

  factory BleState.connected({
    required String deviceName,
    required String deviceId,
    int? rssi,
    List<Map<String, String>> previousDevices = const [],
  }) =>
      BleState(
        status: BleStatus.connected,
        deviceName: deviceName,
        deviceId: deviceId,
        rssi: rssi,
        previousDevices: previousDevices,
      );

  factory BleState.error(String e, {List<Map<String, String>> previousDevices = const []}) =>
      BleState(status: BleStatus.error, error: e, previousDevices: previousDevices);

  BleState copyWith({
    BleStatus? status,
    String? deviceName,
    String? deviceId,
    int? rssi,
    String? error,
    List<Map<String, String>>? previousDevices,
  }) {
    return BleState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      rssi: rssi ?? this.rssi,
      error: error ?? this.error,
      previousDevices: previousDevices ?? this.previousDevices,
    );
  }

  @override
  List<Object?> get props => [status, deviceName, deviceId, rssi, error, previousDevices];
}
