// ════════════════════════════════════════════════════════════════════════
//  AUTO-RECONNECT DECISION TEST
// ════════════════════════════════════════════════════════════════════════
//
//  YAAD RAKHO: asli BLE reconnect (watch wapas connect hua ya nahi) yahan
//  test NAHI ho sakta — wo native Android/iOS + hardware ka kaam hai aur
//  sirf REAL DEVICE pe manually test hota hai.
//
//  Yahan hum sirf "FAISLA" test kar rahe hain: kin conditions me Flutter ko
//  reconnect TRIGGER karna chahiye. Ye HeartBleCubit.shouldReconnect() pure
//  function hai — isliye bina watch, bina Hive, turant chalta hai.
//
//  Chalane ke liye:
//      flutter test test/feature/heart_rate_tracker/heart_ble_reconnect_test.dart
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';

void main() {
  group('HeartBleCubit.shouldReconnect — reconnect karein ya nahi', () {
    // ── HAPPY PATH ────────────────────────────────────────────────────────
    // Connected nahi hai + saved address hai → reconnect karna CHAHIYE.
    test('disconnected hai aur saved address hai → true (reconnect karo)', () {
      final result = HeartBleCubit.shouldReconnect(
        isConnected: false,
        lastDeviceAddress: 'AA:BB:CC:DD:EE:FF',
      );
      expect(result, isTrue);
    });

    // ── GUARD 1 ───────────────────────────────────────────────────────────
    // Pehle se connected hai → dobara connect karne ki zaroorat NAHI.
    test('pehle se connected hai → false (reconnect mat karo)', () {
      final result = HeartBleCubit.shouldReconnect(
        isConnected: true,
        lastDeviceAddress: 'AA:BB:CC:DD:EE:FF',
      );
      expect(result, isFalse);
    });

    // ── GUARD 2 ───────────────────────────────────────────────────────────
    // Koi saved address hi nahi → kis device se connect karein? → false.
    test('address khaali hai → false (kis device se judein?)', () {
      final result = HeartBleCubit.shouldReconnect(
        isConnected: false,
        lastDeviceAddress: '',
      );
      expect(result, isFalse);
    });

    // ── EDGE CASE — dono galat ────────────────────────────────────────────
    // Connected bhi hai aur address bhi khaali (weird state) → safe: false.
    test('connected + address khaali → false', () {
      final result = HeartBleCubit.shouldReconnect(
        isConnected: true,
        lastDeviceAddress: '',
      );
      expect(result, isFalse);
    });
  });
}
