package com.xelec.xelex_esp

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import com.android.chileaf.bluetooth.scanner.ScanCallback
import com.android.chileaf.bluetooth.scanner.ScanResult
import com.android.chileaf.wear.WearManager
import com.android.chileaf.wear.WearManagerCallbacks
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class MainActivity : FlutterActivity() {

    private val TAG = "MainActivity"
    private val METHOD_CHANNEL = "com.example.cl800/sdk_methods"
    private val EVENT_CHANNEL = "com.example.cl800/heartrate_stream"

    private lateinit var wearManager: WearManager
    private var dataSink: EventChannel.EventSink? = null

    private var isConnecting = false
    private var isScanning = false
    private var userInitiatedDisconnect = false

    private val mainHandler = Handler(Looper.getMainLooper())

    private val scanTimeoutRunnable = Runnable {
        if (isScanning) {
            try { wearManager.stopScan() } catch (e: Exception) {}
            isScanning = false
            if (!isConnecting) {
                sendToFlutter("STATUS", "Scan timed out. No device found.")
            }
        }
    }

    private val connectTimeoutRunnable = Runnable {
        if (isConnecting) {
            isConnecting = false
            sendToFlutter("STATUS", "Connection timed out.")
        }
    }

    // Scanned devices store karo MAC address se
    private val foundDevices = HashMap<String, BluetoothDevice>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        wearManager = WearManager.getInstance(this)
        wearManager.setDebug(true)

        // ── Method Channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startScan" -> {
                        if (!isBluetoothReady()) {
                            result.error("BLUETOOTH_OFF", "Bluetooth is disabled", null)
                            return@setMethodCallHandler
                        }
                        if (!isLocationEnabled()) {
                            result.error("LOCATION_OFF", "Location is disabled", null)
                            sendToFlutter("STATUS", "Please enable Location.")
                            try {
                                startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                            } catch (e: Exception) {}
                            return@setMethodCallHandler
                        }
                        isConnecting = false
                        isScanning = true
                        foundDevices.clear()
                        sendToFlutter("STATUS", "Scanning...")
                        startBleScan()
                        result.success("Scan Started")
                    }

                    "stopScan" -> {
                        try { wearManager.stopScan() } catch (e: Exception) {}
                        isScanning = false
                        result.success("Scan Stopped")
                    }

                    "connectToDevice" -> {
                        val args = call.arguments as? Map<*, *>
                        val address = args?.get("uuid") as? String
                        if (address.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "address missing", null)
                            return@setMethodCallHandler
                        }
                        val device = foundDevices[address]
                        if (device != null) {
                            try { wearManager.stopScan() } catch (e: Exception) {}
                            isScanning = false
                            isConnecting = true
                            sendToFlutter("STATUS", "Connecting to ${device.name ?: address}...")
                            mainHandler.removeCallbacks(connectTimeoutRunnable)
                            mainHandler.postDelayed(connectTimeoutRunnable, 20000)
                            wearManager.connect(device, true)
                            result.success("Connecting...")
                        } else {
                            result.error("NOT_FOUND", "Device not found: $address", null)
                        }
                    }

                    "disconnect" -> {
                        userInitiatedDisconnect = true
                        wearManager.disConnect()
                        result.success("Disconnect Command Sent")
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Event Channel ──────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    dataSink = events
                }
                override fun onCancel(arguments: Any?) {
                    dataSink = null
                }
            })

        setupCallbacks()
    }

    private fun startBleScan() {
        mainHandler.removeCallbacks(scanTimeoutRunnable)
        mainHandler.removeCallbacks(connectTimeoutRunnable)
        mainHandler.postDelayed(scanTimeoutRunnable, 15000)

        wearManager.startScan(object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                processScanResult(result)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                super.onBatchScanResults(results)
                for (r in results) processScanResult(r)
            }

            override fun onScanFailed(errorCode: Int) {
                super.onScanFailed(errorCode)
                isScanning = false
                sendToFlutter("STATUS", "Scan Failed (code: $errorCode)")
                Log.e(TAG, "Scan Failed: $errorCode")
            }
        })
    }

    private fun processScanResult(result: ScanResult) {
        val device = result.device
        val name = result.scanRecord?.deviceName ?: device.name ?: "Unknown"
        val address = device.address ?: return

        Log.d(TAG, "Found: name=$name address=$address")

        if (!foundDevices.containsKey(address)) {
            foundDevices[address] = device

            val deviceInfo = HashMap<String, String>()
            deviceInfo["name"] = name
            deviceInfo["uuid"] = address   // Flutter side 'uuid' key expect karta hai
            deviceInfo["rssi"] = result.rssi.toString()
            sendToFlutter("DEVICE_FOUND", deviceInfo)
        }
    }

    private fun sendToFlutter(type: String, value: Any) {
        val dataMap = HashMap<String, Any>()
        dataMap["type"] = type
        dataMap["value"] = value
        mainHandler.post {
            dataSink?.success(dataMap)
        }
    }

    private fun setupCallbacks() {
        wearManager.setManagerCallbacks(object : WearManagerCallbacks {

            override fun onHeartRateMeasurementReceived(
                device: BluetoothDevice,
                heartRate: Int,
                contactDetected: Boolean?,
                energyExpanded: Int?,
                rrIntervals: List<Int>?
            ) {
                Log.d(TAG, "Heart Rate: $heartRate")
                sendToFlutter("HEART_RATE", heartRate)
            }

            override fun onBatteryLevelChanged(device: BluetoothDevice, batteryLevel: Int) {
                sendToFlutter("BATTERY", batteryLevel)
            }

            override fun onDeviceConnected(device: BluetoothDevice) {
                mainHandler.removeCallbacks(scanTimeoutRunnable)
                mainHandler.removeCallbacks(connectTimeoutRunnable)
                isConnecting = false
                userInitiatedDisconnect = false
                sendToFlutter("STATUS", "Connected")
            }

            override fun onDeviceDisconnected(device: BluetoothDevice) {
                isConnecting = false
                if (!userInitiatedDisconnect) {
                    sendToFlutter("STATUS", "Reconnecting...")
                    mainHandler.postDelayed({
                        if (isBluetoothReady() && isLocationEnabled()) {
                            isScanning = true
                            startBleScan()
                        }
                    }, 2000)
                } else {
                    sendToFlutter("STATUS", "Disconnected")
                    userInitiatedDisconnect = false
                }
            }
        })
    }

    private fun isBluetoothReady(): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: run {
            sendToFlutter("STATUS", "Bluetooth not supported")
            return false
        }
        if (!adapter.isEnabled) {
            sendToFlutter("STATUS", "Bluetooth is off")
            try {
                startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
            } catch (e: Exception) {}
            return false
        }
        return true
    }

    private fun isLocationEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val mode = Settings.Secure.getInt(contentResolver, Settings.Secure.LOCATION_MODE)
                mode != Settings.Secure.LOCATION_MODE_OFF
            } catch (e: Settings.SettingNotFoundException) {
                false
            }
        } else true
    }
}
