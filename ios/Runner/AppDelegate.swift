import UIKit
import Flutter
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, BLECentralDelegate {

    private let METHOD_CHANNEL = "com.example.cl800/sdk_methods"
    private let EVENT_CHANNEL  = "com.example.cl800/heartrate_stream"

    private var eventSink: FlutterEventSink?
    private var userInitiatedDisconnect = false
    private var isConnected = false
    private var connectedDeviceName: String?
    private var reconnectTimer: Timer?
    private var rssiTimer: Timer?
    private weak var connectedPeripheral: CBPeripheral?

    private var scannedDevices: [String: FitBLEModel] = [:]

    // MARK: - App Launch

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // 1. SDK initialize
        FitBLEBridge.setup()

        // 2. Delegate set karo
        FitBLECentralManager.shareInstance()._BLECentralDelegate = self

        // 3. Method Channel setup
        let methodChannel = FlutterMethodChannel(
            name: METHOD_CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {

            case "startScan":
                self.scannedDevices = [:]
                self.userInitiatedDisconnect = false
                self.reconnectTimer?.invalidate()
                FitBLEBridge.setScanNameFilter("")
                FitBLECentralManager.shareInstance().centralStartSaomiao()
                self.sendToFlutter(type: "STATUS", value: "Scanning...")
                result("Scan Started")

            case "connectToDevice":
                guard let args = call.arguments as? [String: Any],
                      let uuid = args["uuid"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "uuid missing", details: nil))
                    return
                }
                if let model = self.scannedDevices[uuid] {
                    FitBLEBridge.stopScan()
                    FitBLEBridge.pairDevice(model.peripheral)
                    self.sendToFlutter(type: "STATUS", value: "Connecting to \(model.serviceName ?? uuid)...")
                    result("Connecting...")
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Device not found: \(uuid)", details: nil))
                }

            case "stopScan":
                FitBLEBridge.stopScan()
                result("Scan Stopped")

            case "disconnect":
                self.userInitiatedDisconnect = true
                self.reconnectTimer?.invalidate()
                FitBLECentralManager.shareInstance().dissConnect()
                result("Disconnect Command Sent")

            case "reconnectByAddress":
                // iOS does not support connecting by MAC address directly.
                // Start a short scan — device will auto-connect via
                // fitConnectState when found (same as link-loss recovery).
                self.userInitiatedDisconnect = false
                self.sendToFlutter(type: "STATUS", value: "Reconnecting...")
                FitBLECentralManager.shareInstance().centralStartSaomiao()
                result("Scanning for device...")

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // 4. Event Channel setup
        let eventChannel = FlutterEventChannel(
            name: EVENT_CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Helper

    private func sendToFlutter(type: String, value: Any) {
        guard let sink = eventSink else { return }
        let data: [String: Any] = ["type": type, "value": value]
        DispatchQueue.main.async {
            sink(data)
        }
    }

    // MARK: - BLECentralDelegate callbacks

    func fitScanDeviceArray(_ deviceArr: NSMutableArray?) {
        guard let arr = deviceArr else { return }
        for item in arr {
            guard let model = item as? FitBLEModel else { continue }
            let name = model.serviceName ?? "Unknown"
            let uuid = model.uuidString ?? ""
            let rssi = model.rssiStr ?? "0"
            guard !uuid.isEmpty else { continue }

            scannedDevices[uuid] = model

            let deviceInfo: [String: String] = [
                "name": name,
                "uuid": uuid,
                "rssi": rssi
            ]
            sendToFlutter(type: "DEVICE_FOUND", value: deviceInfo)
        }
    }

    func fitConnectState(_ isConnect: Bool) {
        if isConnect {
            reconnectTimer?.invalidate()
            userInitiatedDisconnect = false
            isConnected = true
            sendToFlutter(type: "STATUS", value: "Connected")

            // Start RSSI polling every 3 seconds
            rssiTimer?.invalidate()
            if let peripheral = FitBLECentralManager.shareInstance().peripheral {
                connectedPeripheral = peripheral
                if let name = peripheral.name, !name.isEmpty {
                    connectedDeviceName = name
                    sendToFlutter(type: "LAST_DEVICE_NAME", value: name)
                }
                peripheral.delegate = self
                rssiTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self, weak peripheral] _ in
                    peripheral?.readRSSI()
                }
                // Read immediately on connect
                peripheral.readRSSI()
            }
        } else {
            // Stop RSSI polling
            rssiTimer?.invalidate()
            rssiTimer = nil
            connectedPeripheral = nil
            isConnected = false

            sendToFlutter(type: "STATUS", value: "Disconnected")
            if !userInitiatedDisconnect {
                reconnectTimer?.invalidate()
                reconnectTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.sendToFlutter(type: "STATUS", value: "Reconnecting...")
                    FitBLECentralManager.shareInstance().centralStartSaomiao()
                }
            }
        }
    }

    func dianciStr(_ dianStr: String?) {
        if let battery = dianStr {
            sendToFlutter(type: "BATTERY", value: battery)
        }
    }

    func fitHeartParamter(_ heartStr: String) {
        sendToFlutter(type: "HEART_RATE", value: heartStr)
    }

    func fitRunSParamter(_ runPara: Int32, andFitKM fitKM: Float, andFitCalor fitCalor: Float) {
        let motionData: [String: Any] = [
            "steps": Int(runPara),
            "distance": fitKM,
            "calories": fitCalor
        ]
        sendToFlutter(type: "MOTION", value: motionData)
    }
}

// MARK: - FlutterStreamHandler

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        // Replay current connection state so a freshly-attached Dart engine
        // learns it's already connected (STATUS:"Connected" is a one-shot event
        // that may have fired before this subscription existed).
        if isConnected {
            sendToFlutter(type: "STATUS", value: "Connected")
            if let name = connectedDeviceName, !name.isEmpty {
                sendToFlutter(type: "LAST_DEVICE_NAME", value: name)
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - CBPeripheralDelegate (RSSI)

extension AppDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        sendToFlutter(type: "RSSI", value: RSSI.intValue)
    }
}
