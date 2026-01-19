import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/game_select_mapper.dart';

import '../../../service/ble_service.dart';
import 'ble_state.dart';

class BleCubit extends Cubit<BleState> {
  final BleService service;
  static const String _lastDevicesKey = 'last_connected_devices_data';
  final GameSelectBleMapper gameSelectBleMapper;
  BleCubit(this.service,this.gameSelectBleMapper) : super(BleState.idle());

  Future<void> loadSavedDevices() async {
    final devices = await _getSavedDevicesFromPrefs();
    emit(state.copyWith(previousDevices: devices));
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    emit(state.copyWith(status: BleStatus.connecting));

    try {
      await service.connect(
        device,
            (connState) async {
          if (connState ==
              BluetoothConnectionState.connected) {
            final name = device.advName.isNotEmpty
                ? device.advName
                : "Unknown Device";
            await _saveDeviceData(device.remoteId.str, name);
            final updatedDevices = await _getSavedDevicesFromPrefs();
            
            emit(
              state.copyWith(
                status: BleStatus.connected,
                deviceName: name,
                deviceId: device.remoteId.str,
                previousDevices: updatedDevices,
              ),
            );
          }

          if (connState ==
              BluetoothConnectionState.disconnected) {
            emit(state.copyWith(status: BleStatus.idle));
          }
        },
            (rssi) {
          if (state.status == BleStatus.connected) {
            emit(state.copyWith(rssi: rssi));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(status: BleStatus.error, error: e.toString()));
    }
  }

  Future<void> _saveDeviceData(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> devicesJson = prefs.getStringList(_lastDevicesKey) ?? [];
    
    List<Map<String, String>> devices = devicesJson
        .map((e) => Map<String, String>.from(json.decode(e)))
        .toList();

    devices.removeWhere((element) => element['id'] == id);
    devices.insert(0, {'id': id, 'name': name});
    
    if (devices.length > 5) {
      devices = devices.sublist(0, 5);
    }
    
    await prefs.setStringList(
      _lastDevicesKey, 
      devices.map((e) => json.encode(e)).toList()
    );
  }

  Future<List<Map<String, String>>> _getSavedDevicesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> devicesJson = prefs.getStringList(_lastDevicesKey) ?? [];
    return devicesJson
        .map((e) => Map<String, String>.from(json.decode(e)))
        .toList();
  }

  // Legacy for backward compatibility if needed by other widgets
  Future<List<Map<String, String>>> getSavedDevices() => _getSavedDevicesFromPrefs();


  void setGame(String id) {
    if (state.status == BleStatus.connected) {
      service.send(id);
    }
  }
}
