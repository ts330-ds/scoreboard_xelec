import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../service/ble_service.dart';
import 'ble_state.dart';

class BleCubit extends Cubit<BleState> {
  final BleService service;

  BleCubit(this.service) : super(BleState.idle());

  // inside BleCubit
  Future<void> connectToId(String deviceId, String name) async {
    try {
      emit(BleState.connecting(previousDevices: state.previousDevices));

      // Create device object directly from the stored ID
      final device = BluetoothDevice.fromId(deviceId);

      // Attempt connection
      await device.connect(
        timeout: const Duration(seconds: 15),
        license: License.free,
      );

      // Once connected, you likely need to discover services
      // (this logic should mirror your standard connect method)

      emit(
        BleState.connected(
          deviceName: name,
          deviceId: deviceId,
          previousDevices: state.previousDevices,
        ),
      );
    } catch (e) {
      emit(
        BleState.error(
          "Failed to reconnect: $e",
          previousDevices: state.previousDevices,
        ),
      );
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    emit(state.copyWith(status: BleStatus.connecting));

    try {
      await service.connect(
        device,
        (connState) async {
          if (connState == BluetoothConnectionState.disconnected) {
            emit(state.copyWith(status: BleStatus.idle));
          }
        },
        (rssi) {
          if (state.status == BleStatus.connected) {
            emit(state.copyWith(rssi: rssi));
          }
        },
      );

      final name = device.advName.isNotEmpty
          ? device.advName
          : "Unknown Device";
      emit(
        state.copyWith(
          status: BleStatus.connected,
          deviceName: name,
          deviceId: device.remoteId.str,
          previousDevices: state.previousDevices,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: BleStatus.error, error: e.toString()));
    }
  }

  void setGame(String id) {
    if (state.status == BleStatus.connected) {
      service.send(id);
    }
  }

  Future<void> disconnectBluetooth() {
    if (state.status == BleStatus.connected) {
      emit(state.copyWith(status: BleStatus.idle));
      return service.disconnect();
    }
    return Future.value();
  }
}
