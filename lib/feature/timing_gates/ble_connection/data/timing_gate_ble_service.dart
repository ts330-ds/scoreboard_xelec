import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Low-level BLE service for the HM-10 (CC2541) module wired to the
/// master ESP32's Serial1 port.
///
/// HM-10 exposes a single transparent UART characteristic:
///   Service  : 0000FFE0-0000-1000-8000-00805F9B34FB
///   Char FFE1: notify (incoming data) + write (outgoing commands)
///
/// Data arrives in ≤20-byte BLE packets. This class buffers them and
/// emits complete newline-terminated lines via [lineStream].
///
/// Usage:
///   await service.connect(device);
///   service.lineStream.listen((line) { ... });
///   await service.send('MODE_LINEAR');
class TimingGateBleService {
  // ── HM-10 UUIDs ───────────────────────────────────────────────────────────
  static final Guid _serviceUuid =
      Guid('0000FFE0-0000-1000-8000-00805F9B34FB');
  static final Guid _charUuid =
      Guid('0000FFE1-0000-1000-8000-00805F9B34FB');

  // ── Internal state ────────────────────────────────────────────────────────
  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _rssiTimer;

  /// Stores the last successfully connected device for auto-reconnect.
  BluetoothDevice? _lastDevice;

  final _lineBuffer = StringBuffer();

  // ── Public streams ────────────────────────────────────────────────────────

  /// Emits every complete newline-terminated line from firmware.
  final _lineController = StreamController<String>.broadcast();
  Stream<String> get lineStream => _lineController.stream;

  /// Emits scan results while scanning.
  final _scanController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanStream => _scanController.stream;

  /// Emits RSSI updates while connected (~3 s interval).
  final _rssiController = StreamController<int>.broadcast();
  Stream<int> get rssiStream => _rssiController.stream;

  /// Fires true on connection, false on disconnect.
  final _connController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connController.stream;

  // ── Accessors ─────────────────────────────────────────────────────────────

  bool get isConnected =>
      _device != null &&
      _char != null &&
      (_device!.isConnected);

  String get connectedDeviceName => _device?.platformName ?? '';

  // ── Scanning ──────────────────────────────────────────────────────────────

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: true,
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _scanController.add(results);
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
  }

  // ── Connection ────────────────────────────────────────────────────────────

  Future<void> connect(BluetoothDevice device) async {
    await disconnect(); // clean up any existing connection
    _device = device;

    // Track connection state changes
    _connSub = device.connectionState.listen((s) {
      final connected = s == BluetoothConnectionState.connected;
      _connController.add(connected);
      if (!connected) {
        _char = null;
        _stopRssi();
        _notifySub?.cancel();
      }
    });

    await device
        .connect(autoConnect: false, license: License.free)
        .timeout(const Duration(seconds: 8));

    // Discover services
    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid == _serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid == _charUuid) {
            _char = c;
            break;
          }
        }
      }
    }

    if (_char == null) {
      await disconnect();
      throw Exception('HM-10 FFE1 characteristic not found. Check UUIDs.');
    }

    // Subscribe to notifications — this is how data arrives from firmware
    await _char!.setNotifyValue(true);
    _notifySub = _char!.lastValueStream.listen(_onData);

    // Save for auto-reconnect
    _lastDevice = device;

    _startRssi();
  }

  // ── Reconnect ───────────────────────────────────────────────────────────

  /// Returns true if there is a previously connected device to reconnect to.
  bool get canReconnect => _lastDevice != null;

  /// Attempts to reconnect to the last connected device.
  /// Throws if no previous device or connection fails.
  Future<void> reconnect() async {
    final device = _lastDevice;
    if (device == null) {
      throw Exception('No previous device to reconnect to.');
    }
    await connect(device);
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  /// Disconnects from the current device.
  /// If [clearLastDevice] is true, auto-reconnect won't be possible.
  /// Pass true when the user manually disconnects.
  Future<void> disconnect({bool clearLastDevice = false}) async {
    _stopRssi();
    await _notifySub?.cancel();
    await _connSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _char = null;
    _lineBuffer.clear();
    if (clearLastDevice) _lastDevice = null;
    _connController.add(false);
  }

  // ── Send command to firmware ───────────────────────────────────────────────

  /// Sends [command] to firmware. Appends `\n` automatically.
  Future<void> send(String command) async {
    if (_char == null) {
      debugPrint('[BLE] send() failed — not connected');
      return;
    }
    try {
      final bytes = utf8.encode('$command\n');
      debugPrint('[BLE] >>> SEND: "$command"');
      await _char!.write(bytes, withoutResponse: false);
    } catch (e) {
      debugPrint('[BLE] >>> SEND ERROR: $e');
    }
  }

  // ── Data reception ────────────────────────────────────────────────────────

  void _onData(List<int> bytes) {
    if (bytes.isEmpty) return;
    final chunk = utf8.decode(bytes, allowMalformed: true);
    _lineBuffer.write(chunk);

    // Emit all complete lines; keep trailing partial in buffer
    final raw = _lineBuffer.toString();
    final parts = raw.split('\n');
    for (int i = 0; i < parts.length - 1; i++) {
      final line = parts[i].trim();
      if (line.isNotEmpty) {
        debugPrint('[BLE] <<< RECV: "$line"');
        _lineController.add(line);
      }
    }
    _lineBuffer.clear();
    _lineBuffer.write(parts.last); // incomplete tail
  }

  // ── RSSI ──────────────────────────────────────────────────────────────────

  void _startRssi() {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        if (_device == null || !_device!.isConnected) return;
        final rssi = await _device!.readRssi();
        _rssiController.add(rssi);
      } catch (_) {}
    });
  }

  void _stopRssi() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await disconnect();
    await _lineController.close();
    await _scanController.close();
    _rssiController.close();
    _connController.close();
  }
}
