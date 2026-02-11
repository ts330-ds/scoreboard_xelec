import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

import '../../../service/dependency_injection/di_service.dart';

class BleService {
  BluetoothDevice? device;
  BluetoothCharacteristic? rxChar;

  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _rssiTimer;
  bool _isConnecting = false;

  // UUIDs ko Guid format mein rakhein
  static final Guid _serviceUuid = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid _rxUuid = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  Future<void> connect(
    BluetoothDevice d,
    void Function(BluetoothConnectionState state) onConn,
    void Function(int rssi) onRssi,
  ) async {
    if (_isConnecting) return;
    _isConnecting = true;
    await disconnect();
    device = d;

    try {
      // 🔔 Connection listener
      _connSub = device!.connectionState.listen((state) {
        onConn(state);
        if (state == BluetoothConnectionState.connected) {
          _startRssiUpdates(onRssi);
        } else {
          _stopRssiUpdates();
        }
      });

      // autoConnect: false hi rakhein fast connection ke liye
      await device!
          .connect(autoConnect: false, license: License.free)
          .timeout(const Duration(seconds: 6));

      // Services Discover karna
      final services = await device!.discoverServices();
      for (final s in services) {
        if (s.uuid == _serviceUuid) {
          for (final c in s.characteristics) {
            if (c.uuid == _rxUuid) {
              rxChar = c;
            }
          }
        }
      }

      if (rxChar == null) {
        sl<GlobalErrorCubit>().showError("X characteristic not found");
        throw Exception("RX characteristic not found");
      }
    } catch (e) {
      sl<GlobalErrorCubit>().showError("Connection Error: $e");
      await disconnect();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  void _startRssiUpdates(void Function(int rssi) onRssi) {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        if (device == null) return;
        final state = await device!.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
          final rssi = await device!.readRssi();
          onRssi(rssi);
        }
      } catch (e) {
        print("RSSI Read Error: $e");
      }
    });
  }

  void _stopRssiUpdates() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  Future<void> disconnect() async {
    _stopRssiUpdates();
    await _connSub?.cancel();
    await device?.disconnect();
    device = null;
    rxChar = null;
  }

  Future<void> send(String data) async {
    if (rxChar == null) {
      sl<GlobalErrorCubit>().showError(
        "Cannot send: RX Characteristic is null and Data is $data",
      );
      return;
    }
    try {
      // Scoreboard ke liye withoutResponse: true behtar hai taaki lag na ho
      await rxChar!.write(data.codeUnits, withoutResponse: false);
      print("Sent: $data");
    } catch (e) {
      sl<GlobalErrorCubit>().showError("Send Error: $e");
    }
  }
}
