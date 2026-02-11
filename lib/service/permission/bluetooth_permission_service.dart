import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_status.dart';

class BluetoothPermissionService {
  /// 🔍 Check only (no popup)
  Future<AppPermissionStatus> check() async {
    try {
      if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.status;
        if (bluetooth.isGranted) {
          return AppPermissionStatus.granted;
        }
        if (bluetooth.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        return AppPermissionStatus.denied;
      }

      if (!Platform.isAndroid) {
        return AppPermissionStatus.granted;
      }

      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdk = androidInfo.version.sdkInt;

      if (sdk >= 31) {
        final scan = await Permission.bluetoothScan.status;
        final connect = await Permission.bluetoothConnect.status;

        if (scan.isGranted && connect.isGranted) {
          return AppPermissionStatus.granted;
        }

        if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }

        return AppPermissionStatus.denied;
      } else {
        final location = await Permission.locationWhenInUse.status;

        if (location.isGranted) {
          return AppPermissionStatus.granted;
        }

        if (location.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }

        return AppPermissionStatus.denied;
      }
    } catch (_) {
      return AppPermissionStatus.denied;
    }
  }

  /// 🔔 Request (shows popup)
  Future<AppPermissionStatus> request() async {
    try {
      if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.request();
        if (bluetooth.isGranted) {
          return AppPermissionStatus.granted;
        }
        if (bluetooth.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        return AppPermissionStatus.denied;
      }

      if (!Platform.isAndroid) {
        return AppPermissionStatus.granted;
      }

      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdk = androidInfo.version.sdkInt;

      Map<Permission, PermissionStatus> result;

      if (sdk >= 31) {
        result = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
      } else {
        result = await [Permission.locationWhenInUse].request();
      }

      if (result.values.every((s) => s.isGranted)) {
        return AppPermissionStatus.granted;
      }

      if (result.values.any((s) => s.isPermanentlyDenied)) {
        return AppPermissionStatus.permanentlyDenied;
      }

      return AppPermissionStatus.denied;
    } catch (_) {
      return AppPermissionStatus.denied;
    }
  }
}
