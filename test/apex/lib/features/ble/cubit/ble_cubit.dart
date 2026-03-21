import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/gate_model.dart';

part 'ble_state.dart';

/// BleCubit — mock BLE for Phase 1.
/// Real flutter_blue_plus integration will replace this in Phase 4.
class BleCubit extends Cubit<BleState> {
  BleCubit() : super(const BleInitial());

  Timer? _mockScanTimer;

  // ── Scan for gates ────────────────────────────────────
  void startScan() {
    emit(const BleScanning());

    // MOCK: after 2s, emit two connected gates
    _mockScanTimer = Timer(const Duration(seconds: 2), () {
      if (isClosed) return;
      emit(BleGatesConnected(
        masterGate: GateModel.mockMaster(),
        slaveGate: GateModel.mockSlave(40.0),
        intermediateGates: const [],
      ));
    });
  }

  void stopScan() {
    _mockScanTimer?.cancel();
    if (state is! BleGatesConnected) {
      emit(const BleInitial());
    }
  }

  // ── Update slave distance (after Step 1 fills it) ─────
  void updateSlaveDistance(double meters) {
    if (state is BleGatesConnected) {
      final s = state as BleGatesConnected;
      emit(s.copyWith(
        slaveGate: s.slaveGate?.copyWith(distanceMeters: meters),
      ));
    }
  }

  // ── Simulate beam break (for testing Run Test) ─────────
  /// Call this to simulate a finish gate beam break in mock mode
  void simulateBeamBreak() {
    emit(BleBeamBreakDetected(timestamp: DateTime.now()));
  }

  // ── Simulate disconnect ───────────────────────────────
  void simulateDisconnect() {
    emit(const BleGateDisconnected(deviceId: 'mock-slave-001', gateName: 'APEX-S01'));
  }

  bool get masterConnected {
    if (state is BleGatesConnected) {
      return (state as BleGatesConnected).masterGate?.isConnected ?? false;
    }
    return false;
  }

  bool get slaveConnected {
    if (state is BleGatesConnected) {
      return (state as BleGatesConnected).slaveGate?.isConnected ?? false;
    }
    return false;
  }

  GateModel? get masterGate =>
      state is BleGatesConnected ? (state as BleGatesConnected).masterGate : null;

  GateModel? get slaveGate =>
      state is BleGatesConnected ? (state as BleGatesConnected).slaveGate : null;

  @override
  Future<void> close() {
    _mockScanTimer?.cancel();
    return super.close();
  }
}
