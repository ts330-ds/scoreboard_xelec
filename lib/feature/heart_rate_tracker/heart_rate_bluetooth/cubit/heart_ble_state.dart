import 'package:equatable/equatable.dart';

class HeartBleDevice {
  final String name;
  final String uuid;
  final int rssi;

  HeartBleDevice({required this.name, required this.uuid, required this.rssi});

  bool get isCompatible {
    final n = name.toUpperCase();
    return n.startsWith('CL') ||
        n.contains('CL800') ||
        n.contains('CL808') ||
        n.contains('HEART') ||
        n.contains('FIT');
  }

  int get signalBars {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }
}

class HeartBleState extends Equatable {
  final String status;
  final List<HeartBleDevice> foundDevices;
  final int heartRate;
  final int battery;
  final bool isConnected;
  final bool isScanning;
  final bool isReconnecting;
  final bool isBluetoothOff;
  final bool isPermissionDenied;
  final bool isNotificationDenied;
  final String lastDevice;
  final String lastDeviceAddress;
  final int connectedRssi;

  // ── Device Info ──
  final String modelName;
  final String firmwareVersion;
  final String hardwareVersion;
  final String softwareVersion;
  final String serialNumber;
  final String systemId;
  final String vendorName;

  // ── Real-time Sport & Health ──
  final int steps;
  final int distance;
  final int calorie;
  final String bodySensorLocation;
  final String bondingStatus;
  final int spo2;
  final int systolic;
  final int diastolic;
  final int stressLevel;
  final double bodyTemp1;
  final double bodyTemp2;
  final double bodyTemp3;
  final int hrMax;
  final List<int> rrIntervals; // latest batch from device
  final List<int> rrBuffer;   // rolling accumulator across notifications
  final double hrv;            // RMSSD in ms, 0.0 if unavailable

  // ── V3 Polling State ──
  final bool isPolling;
  final String pollingJobId;
  final String pollingMessage;

  // ── History Data ──
  final List<Map<dynamic, dynamic>> historySport;
  final List<Map<dynamic, dynamic>> historyHrRecord;
  final List<Map<dynamic, dynamic>> historyHrData;
  final List<Map<dynamic, dynamic>> historyRrRecord;
  final List<Map<dynamic, dynamic>> historyRrData;
  final List<Map<dynamic, dynamic>> historyStepRecord;
  final List<Map<dynamic, dynamic>> historyStepData;
  final List<Map<dynamic, dynamic>> historySleep;
  final Map<dynamic, dynamic>? historySingleRecord;
  final List<Map<dynamic, dynamic>> history3D;
  final List<Map<dynamic, dynamic>> tempHistory3D; 
  final List<Map<dynamic, dynamic>> intervalSteps;
  final List<Map<dynamic, dynamic>> singleTapRecords;
  final List<int> customData;

  const HeartBleState({
    this.status = "Disconnected",
    this.foundDevices = const [],
    this.heartRate = 0,
    this.battery = 0,
    this.isConnected = false,
    this.isScanning = false,
    this.isReconnecting = false,
    this.isBluetoothOff = false,
    this.isPermissionDenied = false,
    this.isNotificationDenied = false,
    this.lastDevice = "",
    this.lastDeviceAddress = "",
    this.connectedRssi = 0,
    this.modelName = "",
    this.firmwareVersion = "",
    this.hardwareVersion = "",
    this.softwareVersion = "",
    this.serialNumber = "",
    this.systemId = "",
    this.vendorName = "",
    this.steps = 0,
    this.distance = 0,
    this.calorie = 0,
    this.bodySensorLocation = "",
    this.bondingStatus = "",
    this.spo2 = 0,
    this.systolic = 0,
    this.diastolic = 0,
    this.stressLevel = 0,
    this.bodyTemp1 = 0.0,
    this.bodyTemp2 = 0.0,
    this.bodyTemp3 = 0.0,
    this.hrMax = 0,
    this.rrIntervals = const [],
    this.rrBuffer = const [],
    this.hrv = 0.0,
    this.isPolling = false,
    this.pollingJobId = '',
    this.pollingMessage = '',
    this.historySport = const [],
    this.historyHrRecord = const [],
    this.historyHrData = const [],
    this.historyRrRecord = const [],
    this.historyRrData = const [],
    this.historyStepRecord = const [],
    this.historyStepData = const [],
    this.historySleep = const [],
    this.historySingleRecord,
    this.history3D = const [],
    this.tempHistory3D = const [],
    this.intervalSteps = const [],
    this.singleTapRecords = const [],
    this.customData = const [],
  });

  int get signalBars {
    if (connectedRssi == 0) return 0;
    if (connectedRssi >= -60) return 3;
    if (connectedRssi >= -75) return 2;
    if (connectedRssi >= -90) return 1;
    return 0;
  }

  bool get hasDeviceInfo =>
      modelName.isNotEmpty ||
      firmwareVersion.isNotEmpty ||
      hardwareVersion.isNotEmpty ||
      softwareVersion.isNotEmpty ||
      serialNumber.isNotEmpty ||
      vendorName.isNotEmpty ||
      bodySensorLocation.isNotEmpty;

  bool get hasSportData => steps > 0 || distance > 0 || calorie > 0;

  bool get hasHealthData =>
      spo2 > 0 ||
      systolic > 0 ||
      diastolic > 0 ||
      stressLevel > 0 ||
      bodyTemp1 > 0 ||
      hrMax > 0;

  bool get hasHistoryData =>
      historySport.isNotEmpty ||
      historyHrData.isNotEmpty ||
      historySleep.isNotEmpty ||
      historyStepData.isNotEmpty ||
      intervalSteps.isNotEmpty;

  HeartBleState copyWith({
    String? status,
    List<HeartBleDevice>? foundDevices,
    int? heartRate,
    int? battery,
    bool? isConnected,
    bool? isScanning,
    bool? isReconnecting,
    bool? isBluetoothOff,
    bool? isPermissionDenied,
    bool? isNotificationDenied,
    String? lastDevice,
    String? lastDeviceAddress,
    int? connectedRssi,
    String? modelName,
    String? firmwareVersion,
    String? hardwareVersion,
    String? softwareVersion,
    String? serialNumber,
    String? systemId,
    String? vendorName,
    int? steps,
    int? distance,
    int? calorie,
    String? bodySensorLocation,
    String? bondingStatus,
    int? spo2,
    int? systolic,
    int? diastolic,
    int? stressLevel,
    double? bodyTemp1,
    double? bodyTemp2,
    double? bodyTemp3,
    int? hrMax,
    List<int>? rrIntervals,
    List<int>? rrBuffer,
    double? hrv,
    bool? isPolling,
    String? pollingJobId,
    String? pollingMessage,
    List<Map<dynamic, dynamic>>? historySport,
    List<Map<dynamic, dynamic>>? historyHrRecord,
    List<Map<dynamic, dynamic>>? historyHrData,
    List<Map<dynamic, dynamic>>? historyRrRecord,
    List<Map<dynamic, dynamic>>? historyRrData,
    List<Map<dynamic, dynamic>>? historyStepRecord,
    List<Map<dynamic, dynamic>>? historyStepData,
    List<Map<dynamic, dynamic>>? historySleep,
    Map<dynamic, dynamic>? historySingleRecord,
    List<Map<dynamic, dynamic>>? history3D,
    List<Map<dynamic, dynamic>>? tempHistory3D,
    List<Map<dynamic, dynamic>>? intervalSteps,
    List<Map<dynamic, dynamic>>? singleTapRecords,
    List<int>? customData,
  }) {
    return HeartBleState(
      status: status ?? this.status,
      foundDevices: foundDevices ?? this.foundDevices,
      heartRate: heartRate ?? this.heartRate,
      battery: battery ?? this.battery,
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isBluetoothOff: isBluetoothOff ?? this.isBluetoothOff,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isNotificationDenied: isNotificationDenied ?? this.isNotificationDenied,
      lastDevice: lastDevice ?? this.lastDevice,
      lastDeviceAddress: lastDeviceAddress ?? this.lastDeviceAddress,
      connectedRssi: connectedRssi ?? this.connectedRssi,
      modelName: modelName ?? this.modelName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      serialNumber: serialNumber ?? this.serialNumber,
      systemId: systemId ?? this.systemId,
      vendorName: vendorName ?? this.vendorName,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calorie: calorie ?? this.calorie,
      bodySensorLocation: bodySensorLocation ?? this.bodySensorLocation,
      bondingStatus: bondingStatus ?? this.bondingStatus,
      spo2: spo2 ?? this.spo2,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      stressLevel: stressLevel ?? this.stressLevel,
      bodyTemp1: bodyTemp1 ?? this.bodyTemp1,
      bodyTemp2: bodyTemp2 ?? this.bodyTemp2,
      bodyTemp3: bodyTemp3 ?? this.bodyTemp3,
      hrMax: hrMax ?? this.hrMax,
      rrIntervals: rrIntervals ?? this.rrIntervals,
      rrBuffer: rrBuffer ?? this.rrBuffer,
      hrv: hrv ?? this.hrv,
      isPolling: isPolling ?? this.isPolling,
      pollingJobId: pollingJobId ?? this.pollingJobId,
      pollingMessage: pollingMessage ?? this.pollingMessage,
      historySport: historySport ?? this.historySport,
      historyHrRecord: historyHrRecord ?? this.historyHrRecord,
      historyHrData: historyHrData ?? this.historyHrData,
      historyRrRecord: historyRrRecord ?? this.historyRrRecord,
      historyRrData: historyRrData ?? this.historyRrData,
      historyStepRecord: historyStepRecord ?? this.historyStepRecord,
      historyStepData: historyStepData ?? this.historyStepData,
      historySleep: historySleep ?? this.historySleep,
      historySingleRecord: historySingleRecord ?? this.historySingleRecord,
      history3D: history3D ?? this.history3D,
      tempHistory3D: tempHistory3D ?? this.tempHistory3D,
      intervalSteps: intervalSteps ?? this.intervalSteps,
      singleTapRecords: singleTapRecords ?? this.singleTapRecords,
      customData: customData ?? this.customData,
    );
  }

  @override
  List<Object?> get props => [
    status, foundDevices, heartRate, battery, isConnected, isScanning, 
    isReconnecting, isBluetoothOff, isPermissionDenied, isNotificationDenied, lastDevice,
    lastDeviceAddress, connectedRssi, modelName, firmwareVersion, 
    hardwareVersion, softwareVersion, serialNumber, systemId, vendorName, 
    steps, distance, calorie, bodySensorLocation, bondingStatus, spo2, 
    systolic, diastolic, stressLevel, bodyTemp1, bodyTemp2, bodyTemp3, 
    hrMax, rrIntervals, rrBuffer, hrv, isPolling, pollingJobId, pollingMessage,
    historySport, historyHrRecord, historyHrData, historyRrRecord,
    historyRrData, historyStepRecord, historyStepData, historySleep, 
    historySingleRecord, history3D, tempHistory3D, intervalSteps, 
    singleTapRecords, customData,
  ];
}