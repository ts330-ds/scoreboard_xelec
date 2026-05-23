import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';

import 'battery_optimization_state.dart';

class BatteryOptimizationCubit extends Cubit<BatteryOptimizationState> {
  BatteryOptimizationCubit() : super(const BatteryOptimizationState());

  Future<void> load() async {
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    String mfr = '';
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      mfr = info.manufacturer.toLowerCase();
    }
    if (isClosed) return;
    emit(state.copyWith(ignoring: ignoring, manufacturer: mfr));
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    if (state.busy || state.ignoring) return;
    emit(state.copyWith(busy: true));
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    // System dialog dismiss hone ke baad status thoda lag ke update hota hai.
    await Future.delayed(const Duration(milliseconds: 400));
    final ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (isClosed) return;
    emit(state.copyWith(ignoring: ignoring, busy: false));
  }

  Future<void> openAutoStartSettings() async {
    // OEM-specific Auto-start toggles ka koi standard API nahi hai.
    // App-info screen kholte hain — wahin Vivo/Xiaomi/Oppo apne custom
    // "Auto-start", "Background activity", "Battery usage" entries dikhaate hain.
    await openAppSettings();
  }

  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.batteryOptPromptShown, true);
  }
}
