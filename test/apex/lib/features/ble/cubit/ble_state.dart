part of 'ble_cubit.dart';

abstract class BleState extends Equatable {
  const BleState();
  @override List<Object?> get props => [];
}

class BleInitial extends BleState {
  const BleInitial();
}

class BleScanning extends BleState {
  const BleScanning();
}

class BleGatesConnected extends BleState {
  final GateModel? masterGate;
  final GateModel? slaveGate;
  final List<GateModel> intermediateGates;

  const BleGatesConnected({
    this.masterGate,
    this.slaveGate,
    this.intermediateGates = const [],
  });

  bool get masterConnected => masterGate?.isConnected ?? false;
  bool get slaveConnected  => slaveGate?.isConnected ?? false;
  bool get allReady => masterConnected && slaveConnected;

  BleGatesConnected copyWith({
    GateModel? masterGate,
    GateModel? slaveGate,
    List<GateModel>? intermediateGates,
  }) {
    return BleGatesConnected(
      masterGate: masterGate ?? this.masterGate,
      slaveGate: slaveGate ?? this.slaveGate,
      intermediateGates: intermediateGates ?? this.intermediateGates,
    );
  }

  @override
  List<Object?> get props => [masterGate, slaveGate, intermediateGates];
}

class BleGateDisconnected extends BleState {
  final String deviceId;
  final String gateName;
  const BleGateDisconnected({required this.deviceId, required this.gateName});
  @override List<Object?> get props => [deviceId, gateName];
}

class BleBeamBreakDetected extends BleState {
  final DateTime timestamp;
  const BleBeamBreakDetected({required this.timestamp});
  @override List<Object?> get props => [timestamp];
}

class BleError extends BleState {
  final String message;
  const BleError({required this.message});
  @override List<Object?> get props => [message];
}
