// ════════════════════════════════════════════════════════════════════════
//  HeartBleState + HeartBleDevice — PURE FUNCTION TESTS
// ════════════════════════════════════════════════════════════════════════
//
//  Ye test file sirf "pure" functions ko test karta hai — yaani aise functions
//  jinme input do aur output aata hai, koi BLE/internet/phone nahi chahiye.
//  Isliye ye test 1-2 second me chalte hain aur bilkul reliable hote hain.
//
//  Chalane ke liye terminal me:
//      flutter test test/feature/heart_rate_tracker/heart_ble_state_test.dart
//
//  Saare test ek saath chalane ke liye:
//      flutter test
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────
  //  GROUP 1: HeartBleDevice.isCompatible
  //  Ye batata hai ki mila hua device humara watch hai ya nahi (naam se).
  // ──────────────────────────────────────────────────────────────────────
  group('HeartBleDevice.isCompatible', () {
    // Chota helper — bar bar uuid/rssi likhne se bachne ke liye.
    HeartBleDevice deviceNamed(String name) =>
        HeartBleDevice(name: name, uuid: 'x', rssi: -50);

    test('naam "CL800" ho to compatible true hona chahiye', () {
      // ARRANGE + ACT + ASSERT — sab ek line me kyunki simple hai
      expect(deviceNamed('CL800').isCompatible, isTrue);
    });

    test('naam "CL808 Band" ho to bhi compatible', () {
      expect(deviceNamed('CL808 Band').isCompatible, isTrue);
    });

    test('naam me "HEART" ho to compatible', () {
      expect(deviceNamed('My HEART Monitor').isCompatible, isTrue);
    });

    // ── EDGE CASE — yahi asli bug pakadta hai ─────────────────────────────
    // Code uppercase me convert karta hai (n.toUpperCase()), to lowercase
    // "cl800" bhi match hona chahiye. Agar ye fail hua to bug mila!
    test('lowercase "cl800" bhi compatible hona chahiye', () {
      expect(deviceNamed('cl800').isCompatible, isTrue);
    });

    test('bilkul alag naam "Samsung TV" compatible NAHI hona chahiye', () {
      expect(deviceNamed('Samsung TV').isCompatible, isFalse);
    });

    // ── EDGE CASE — khaali naam crash to nahi karta? ──────────────────────
    test('khaali naam "" pe crash nahi, sirf false aana chahiye', () {
      expect(deviceNamed('').isCompatible, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  //  GROUP 2: HeartBleDevice.signalBars
  //  rssi (signal strength) ko 0-3 bars me convert karta hai.
  //  BOUNDARY values pe test karna zaroori — bug aksar ">=" vs ">" me hota.
  // ──────────────────────────────────────────────────────────────────────
  group('HeartBleDevice.signalBars', () {
    HeartBleDevice deviceRssi(int rssi) =>
        HeartBleDevice(name: 'CL800', uuid: 'x', rssi: rssi);

    test('strong signal (-50) → 3 bars', () {
      expect(deviceRssi(-50).signalBars, 3);
    });

    // Boundary: code kehta hai rssi >= -60 → 3 bars. To exactly -60 = 3.
    test('boundary -60 → 3 bars (kyunki >= -60)', () {
      expect(deviceRssi(-60).signalBars, 3);
    });

    test('-61 → 2 bars (boundary ke just neeche)', () {
      expect(deviceRssi(-61).signalBars, 2);
    });

    test('medium (-75) → 2 bars', () {
      expect(deviceRssi(-75).signalBars, 2);
    });

    test('weak (-90) → 1 bar', () {
      expect(deviceRssi(-90).signalBars, 1);
    });

    test('bahut weak (-100) → 0 bars', () {
      expect(deviceRssi(-100).signalBars, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  //  GROUP 3: HeartBleState.signalBars
  //  Ye state wala alag hai — iska special rule: connectedRssi == 0 to 0 bars
  //  (matlab connect hi nahi hai). Ye rule device wale me nahi tha.
  // ──────────────────────────────────────────────────────────────────────
  group('HeartBleState.signalBars', () {
    test('default state (connectedRssi 0) → 0 bars', () {
      // const HeartBleState() = sab default values
      expect(const HeartBleState().signalBars, 0);
    });

    test('connectedRssi -50 → 3 bars', () {
      // copyWith se sirf ek field badal ke naya state banao
      final s = const HeartBleState().copyWith(connectedRssi: -50);
      expect(s.signalBars, 3);
    });

    test('connectedRssi -80 → 1 bar', () {
      final s = const HeartBleState().copyWith(connectedRssi: -80);
      expect(s.signalBars, 1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  //  GROUP 4: HeartBleState.hasHealthData
  //  Koi bhi health value > 0 ho to true. Sab 0 ho to false.
  //  Ye UI me "Health card dikhana hai ya nahi" decide karta hai.
  // ──────────────────────────────────────────────────────────────────────
  group('HeartBleState.hasHealthData', () {
    test('sab default (sab 0) → false', () {
      expect(const HeartBleState().hasHealthData, isFalse);
    });

    test('spo2 aa gaya → true', () {
      final s = const HeartBleState().copyWith(spo2: 98);
      expect(s.hasHealthData, isTrue);
    });

    test('sirf hrMax aaya → true', () {
      final s = const HeartBleState().copyWith(hrMax: 180);
      expect(s.hasHealthData, isTrue);
    });

    // ── EDGE CASE ─────────────────────────────────────────────────────────
    // heartRate health-data me count NAHI hota (code dekho — hasHealthData me
    // heartRate nahi hai). To sirf heartRate set karne pe bhi false aana chahiye.
    test('sirf heartRate set ho to hasHealthData false rehna chahiye', () {
      final s = const HeartBleState().copyWith(heartRate: 72);
      expect(s.hasHealthData, isFalse);
    });
  });
}
