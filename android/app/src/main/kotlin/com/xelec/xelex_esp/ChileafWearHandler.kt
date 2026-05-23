package com.xelec.xelex_esp

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresPermission
import com.android.chileaf.WearManager
import com.android.chileaf.fitness.callback.WearManagerCallbacks
import com.android.chileaf.fitness.common.FilterScanCallback
import io.flutter.plugin.common.EventChannel
import no.nordicsemi.android.support.v18.scanner.ScanResult
import java.util.HashMap

class ChileafWearHandler(
    private val context: Context,
    private val wearManager: WearManager,
    private val mainHandler: Handler = Handler(Looper.getMainLooper())
) {

    private val TAG = "ChileafWearHandler"

    var dataSink: EventChannel.EventSink? = null

    private var isConnecting = false
    private var isScanning = false
    private var userInitiatedDisconnect = false
    private var lastConnectedDevice: BluetoothDevice? = null

    private val foundDevices = HashMap<String, BluetoothDevice>()

    /** Exposed so MainActivity can guard sync calls */
    val isDeviceConnected: Boolean get() = wearManager.isConnected

    // ── RSSI polling ─────────────────────────────────────────────────────────
    private var rssiRunnable: Runnable? = null

    // ── Two-step accumulation: HR Record → HR Data ────────────────────────────
    private val hrDataLock = Any()
    private var pendingHrDataCount = 0
    private val accumulatedHrData = mutableListOf<HashMap<String, Any>>()

    // ── Two-step accumulation: RR Record → RR Data ────────────────────────────
    private val rrDataLock = Any()
    private var pendingRrDataCount = 0
    private val accumulatedRrData = mutableListOf<HashMap<String, Any>>()

    // ── History range filter (0 / MAX = no filter, i.e. fetch everything) ────
    // Set via syncHistoryRange(); record-callbacks compare item.stamp against
    // this window before triggering per-stamp data fetches.
    //
    // IMPORTANT: Device records are SESSIONS, not point-in-time events.
    // A record's `stamp` is when that session STARTED — it may contain readings
    // spanning many hours after that. So we apply a session-buffer on the FROM
    // side: include records that started up to SESSION_LOOKBACK_SEC before the
    // requested window. The actual per-reading filter happens Flutter-side.
    @Volatile private var rangeFromSec: Long = 0L
    @Volatile private var rangeToSec: Long = Long.MAX_VALUE

    // 24 hours — covers any realistic single recording session on the device.
    private val SESSION_LOOKBACK_SEC = 24L * 60L * 60L

    private fun stampInRange(stamp: Long): Boolean {
        val fromWithBuffer = if (rangeFromSec > SESSION_LOOKBACK_SEC) {
            rangeFromSec - SESSION_LOOKBACK_SEC
        } else {
            0L
        }
        return stamp in fromWithBuffer..rangeToSec
    }


    // ── RSSI polling ──────────────────────────────────────────────────────────
    private fun startRssiPolling() {
        stopRssiPolling()
        val r = object : Runnable {
            override fun run() {
                triggerRssiRead()
                mainHandler.postDelayed(this, 3000)
            }
        }
        rssiRunnable = r
        mainHandler.postDelayed(r, 1500)
    }

    private fun stopRssiPolling() {
        rssiRunnable?.let { mainHandler.removeCallbacks(it) }
        rssiRunnable = null
    }

    private fun getBluetoothGatt(): BluetoothGatt? {
        return try {
            val bleManagerClass = wearManager.javaClass.superclass?.superclass ?: return null
            val requestHandlerField = bleManagerClass.getDeclaredField("requestHandler")
            requestHandlerField.isAccessible = true
            val requestHandler = requestHandlerField.get(wearManager) ?: return null

            val bleManagerHandlerClass = requestHandler.javaClass.superclass ?: return null
            val gattField = bleManagerHandlerClass.getDeclaredField("bluetoothGatt")
            gattField.isAccessible = true
            gattField.get(requestHandler) as? BluetoothGatt
        } catch (e: Exception) {
            // Log.w(TAG, "getBluetoothGatt failed: ${e.message}")
            null
        }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    private fun triggerRssiRead() {
        if (!wearManager.isConnected) return
        val gatt = getBluetoothGatt()
        if (gatt == null) {
            // Log.w(TAG, "triggerRssiRead: gatt is null")
            return
        }
        val ok = gatt.readRemoteRssi()
        // Log.d(TAG, ">>> readRemoteRssi() called, queued=$ok")
    }

    // ── Timeout runnables ─────────────────────────────────────────────────────
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
            // Log.d(TAG, "Connection/reconnection timed out")
            sendToFlutter("STATUS", "Disconnected")
        }
    }

    // ── Initialization ────────────────────────────────────────────────────────
    fun init() {
        try {
            stopRssiPolling()
            wearManager.disconnectDevice()
        } catch (e: Exception) {
            // Log.w(TAG, "Pre-init disconnect failed (safe to ignore): ${e.message}")
        }
        wearManager.setDebug(true)
        setupConnectionCallbacks()
        registerDataCallbacks()
    }

    // ── Scan ──────────────────────────────────────────────────────────────────
    fun startScan() {
        isConnecting = false
        isScanning = true
        foundDevices.clear()
        sendToFlutter("STATUS", "Scanning...")

        mainHandler.removeCallbacks(scanTimeoutRunnable)
        mainHandler.removeCallbacks(connectTimeoutRunnable)
        mainHandler.postDelayed(scanTimeoutRunnable, 15000)

        wearManager.startScan(object : FilterScanCallback {
            override fun onFilterScanResults(results: List<ScanResult>) {
                for (r in results) processScanResult(r)
            }

            override fun onScanResult(callbackType: Int, result: ScanResult) {
                processScanResult(result)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                for (r in results) processScanResult(r)
            }

            override fun onScanFailed(errorCode: Int) {
                isScanning = false
                sendToFlutter("STATUS", "Scan Failed (code: $errorCode)")
                // Log.e(TAG, "Scan Failed: $errorCode")
            }
        })
    }

    fun stopScan() {
        try { wearManager.stopScan() } catch (e: Exception) {}
        isScanning = false
    }

    // ── Connect / Disconnect ──────────────────────────────────────────────────
    @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
    fun connectToDevice(address: String): Boolean {
        val device = foundDevices[address] ?: return false
        stopScan()
        isConnecting = true
        sendToFlutter("STATUS", "Connecting to ${device.name ?: address}...")
        mainHandler.removeCallbacks(connectTimeoutRunnable)
        mainHandler.postDelayed(connectTimeoutRunnable, 20000)
        wearManager.connectDevice(device)
        return true
    }

    fun disconnect() {
        userInitiatedDisconnect = true
        lastConnectedDevice = null
        stopRssiPolling()
        wearManager.disconnectDevice()

    }

    // ── History Sync ──────────────────────────────────────────────────────────
    /**
     * Requests ALL history categories from the device.
     * Results arrive asynchronously via the registered callbacks.
     * HR / RR / Step data is auto-fetched after their record headers arrive.
     */
    fun syncAllHistory() {
        // Log.d(TAG, ">>> syncAllHistory()")
        rangeFromSec = 0L
        rangeToSec = Long.MAX_VALUE
        sendToFlutter("HISTORY_SYNC_START", "syncing")
        try { wearManager.getHistoryOfHRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfHRRecord: ${e.message}") }
        // Stagger requests so they don't compete in the device's BLE queue
        mainHandler.postDelayed({
            try {
                // Log.d(TAG, ">>> calling getHistoryOfRRRecord()")
                wearManager.getHistoryOfRRRecord()
            } catch (e: Exception) { Log.w(TAG, "getHistoryOfRRRecord: ${e.message}") }
        }, 1500L)
        mainHandler.postDelayed({
            try {
                // Log.d(TAG, ">>> calling getHistoryOfSleep()")
                wearManager.getHistoryOfSleep()
                // Log.d(TAG, ">>> getHistoryOfSleep() called OK")
            } catch (e: Exception) { Log.e(TAG, "getHistoryOfSleep FAILED: ${e.message}") }
        }, 3000L)
    }

    /**
     * Range-filtered history sync.
     *
     * SDK does not expose a native range API — it always returns ALL record
     * headers. We filter those headers in the callbacks so only stamps within
     * [fromMs, toMs] trigger per-record `getHistoryOf*Data(stamp)` calls.
     * This skips BLE traffic for out-of-range records.
     *
     * Sleep does not support filtering at the SDK level (one-shot list);
     * Flutter filters sleep data client-side.
     */
    fun syncHistoryRange(fromMs: Long, toMs: Long) {
        rangeFromSec = if (fromMs > 0L) fromMs / 1000L else 0L
        rangeToSec = if (toMs > 0L) toMs / 1000L else Long.MAX_VALUE
        // Log.d(TAG, ">>> syncHistoryRange(from=$rangeFromSec to=$rangeToSec sec)")
        sendToFlutter("HISTORY_SYNC_START", "syncing")
        try { wearManager.getHistoryOfHRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfHRRecord: ${e.message}") }
        mainHandler.postDelayed({
            try { wearManager.getHistoryOfRRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfRRRecord: ${e.message}") }
        }, 1500L)
        mainHandler.postDelayed({
            try { wearManager.getHistoryOfSleep() } catch (e: Exception) { Log.e(TAG, "getHistoryOfSleep FAILED: ${e.message}") }
        }, 3000L)
    }

    /** Single-record lookup by timestamp */
    fun syncHistorySingleRecord(stamp: Long) {
        try { wearManager.getHistoryOfSingleRecord(stamp) } catch (e: Exception) {
            // Log.w(TAG, "getHistoryOfSingleRecord: ${e.message}")
        }
    }

    // ── Cleanup ───────────────────────────────────────────────────────────────
    fun destroy() {
        try {
            stopRssiPolling()
            mainHandler.removeCallbacks(scanTimeoutRunnable)
            mainHandler.removeCallbacks(connectTimeoutRunnable)
            wearManager.disconnectDevice()
        } catch (e: Exception) {
            // Log.w(TAG, "destroy error: ${e.message}")
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────
    @SuppressLint("MissingPermission")
    private fun processScanResult(result: ScanResult) {
        val device = result.device
        val name = result.scanRecord?.deviceName ?: device.name ?: "Unknown"
        val address = device.address ?: return

        // Log.d(TAG, "Found: name=$name address=$address")

        if (!foundDevices.containsKey(address)) {
            foundDevices[address] = device

            val deviceInfo = HashMap<String, String>()
            deviceInfo["name"] = name
            deviceInfo["uuid"] = address
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

    // ═══════════════════════════════════════════════════════════════════════════
    // Connection lifecycle callbacks (via setManagerCallbacks)
    // ═══════════════════════════════════════════════════════════════════════════
    private fun setupConnectionCallbacks() {
        wearManager.setManagerCallbacks(object : WearManagerCallbacks {
            override fun onHeartRateMeasurementReceived(
                device: BluetoothDevice,
                heartRate: Int,
                contactDetected: Boolean?,
                energyExpanded: Int?,
                rrIntervals: List<Int>?
            ) {
                // Log.d(TAG, "Heart Rate: $heartRate, rrIntervals=${rrIntervals?.size ?: 0}")
                val map = HashMap<String, Any?>()
                map["heartRate"] = heartRate
                map["contactDetected"] = contactDetected
                map["energyExpended"] = energyExpanded
                map["rrIntervals"] = rrIntervals
                sendToFlutter("HEART_RATE_MEASUREMENT", map)
            }

            override fun onBatteryLevelChanged(device: BluetoothDevice, batteryLevel: Int) {
                sendToFlutter("BATTERY", batteryLevel)
            }

            override fun onDeviceConnected(device: BluetoothDevice) {
                mainHandler.removeCallbacks(scanTimeoutRunnable)
                mainHandler.removeCallbacks(connectTimeoutRunnable)
                isConnecting = false
                userInitiatedDisconnect = false
                lastConnectedDevice = device
                sendToFlutter("STATUS", "Connected")
                sendToFlutter("LAST_DEVICE_ADDRESS", device.address ?: "")
                startRssiPolling()
                try { wearManager.setUTCTime() } catch (e: Exception) { Log.w(TAG, "setUTCTime: ${e.message}") }
            }

            override fun onRssiRead(device: BluetoothDevice, rssi: Int) {
                // Log.d(TAG, "RSSI: $rssi dBm")
                sendToFlutter("RSSI", rssi)
            }

            override fun onBodySensorLocationReceived(
                device: BluetoothDevice,
                sensorLocation: Int
            ) {
                val locationName = when (sensorLocation) {
                    1 -> "Chest"
                    2 -> "Wrist"
                    3 -> "Finger"
                    4 -> "Hand"
                    5 -> "Ear Lobe"
                    6 -> "Foot"
                    else -> "Other"
                }
                sendToFlutter("BODY_SENSOR_LOCATION", locationName)
            }

            override fun onSportReceived(
                device: BluetoothDevice,
                step: Int,
                distance: Int,
                calorie: Int
            ) {
                val sportMap = HashMap<String, Int>()
                sportMap["step"] = step
                sportMap["distance"] = distance
                sportMap["calorie"] = calorie
                sendToFlutter("SPORT", sportMap)
            }

            override fun onSystemId(device: BluetoothDevice, systemId: String?) {
                sendToFlutter("SYSTEM_ID", systemId ?: "")
            }

            override fun onModelName(device: BluetoothDevice, modelName: String?) {
                sendToFlutter("MODEL_NAME", modelName ?: "")
            }

            override fun onSerialNumber(device: BluetoothDevice, serialNumber: String?) {
                sendToFlutter("SERIAL_NUMBER", serialNumber ?: "")
            }

            override fun onFirmwareVersion(device: BluetoothDevice, firmware: String?) {
                sendToFlutter("FIRMWARE_VERSION", firmware ?: "")
            }

            override fun onHardwareVersion(device: BluetoothDevice, hardware: String?) {
                sendToFlutter("HARDWARE_VERSION", hardware ?: "")
            }

            override fun onSoftwareVersion(device: BluetoothDevice, software: String?) {
                sendToFlutter("SOFTWARE_VERSION", software ?: "")
            }

            override fun onVendorName(device: BluetoothDevice, vendorName: String?) {
                sendToFlutter("VENDOR_NAME", vendorName ?: "")
            }

            override fun onDeviceConnecting(device: BluetoothDevice) {}

            override fun onDeviceDisconnecting(device: BluetoothDevice) {}

            override fun onLinkLossOccurred(device: BluetoothDevice) {
                // Log.d(TAG, "Link loss occurred: ${device.address}")
                if (userInitiatedDisconnect) return
                sendToFlutter("STATUS", "Reconnecting...")

                mainHandler.postDelayed({
                    if (isConnecting || userInitiatedDisconnect) return@postDelayed
                    val last = lastConnectedDevice ?: run {
                        sendToFlutter("STATUS", "Disconnected")
                        return@postDelayed
                    }
                    // Log.d(TAG, ">>> Reconnecting after link loss: ${last.address}")
                    isConnecting = true
                    mainHandler.removeCallbacks(connectTimeoutRunnable)
                    mainHandler.postDelayed(connectTimeoutRunnable, 20000)
                    try {
                        wearManager.connectDevice(last)
                    } catch (se: SecurityException) {
                        // Log.e(TAG, "SecurityException on link-loss reconnect: ${se.message}")
                        isConnecting = false
                        sendToFlutter("STATUS", "Disconnected")
                    } catch (e: Exception) {
                        // Log.e(TAG, "Exception on link-loss reconnect: ${e.message}")
                        isConnecting = false
                        sendToFlutter("STATUS", "Disconnected")
                    }
                }, 2000)
            }

            override fun onServicesDiscovered(
                device: BluetoothDevice,
                optionalServicesFound: Boolean
            ) {}

            override fun onDeviceReady(device: BluetoothDevice) {}

            override fun onBondingRequired(device: BluetoothDevice) {
                sendToFlutter("BONDING", "required")
            }

            override fun onBonded(device: BluetoothDevice) {
                sendToFlutter("BONDING", "bonded")
            }

            override fun onBondingFailed(device: BluetoothDevice) {
                sendToFlutter("BONDING", "failed")
            }

            override fun onError(device: BluetoothDevice, message: String, errorCode: Int) {
                // Log.e(TAG, "SDK Error: $message (code: $errorCode)")
                sendToFlutter("ERROR", "$message (code: $errorCode)")
            }

            override fun onDeviceNotSupported(device: BluetoothDevice) {
                sendToFlutter("STATUS", "Device Not Supported")
            }

            override fun onDeviceDisconnected(device: BluetoothDevice) {
                isConnecting = false
                stopRssiPolling()

                if (userInitiatedDisconnect) {
                    // User pressed disconnect — clean break
                    userInitiatedDisconnect = false
                    lastConnectedDevice = null
                    sendToFlutter("STATUS", "Disconnected")

                } else {
                    // Unexpected disconnect (out of range, BLE reset, etc.)
                    // → try auto-reconnect, fall back to "Disconnected" on failure
                    // Log.d(TAG, "Unexpected disconnect: ${device.address}")
                    sendToFlutter("STATUS", "Reconnecting...")

                    val last = lastConnectedDevice
                    if (last == null) {
                        sendToFlutter("STATUS", "Disconnected")
                        return
                    }

                    mainHandler.postDelayed({
                        if (isConnecting || userInitiatedDisconnect) return@postDelayed
                        // Log.d(TAG, ">>> Auto-reconnect attempt: ${last.address}")
                        isConnecting = true
                        mainHandler.removeCallbacks(connectTimeoutRunnable)
                        mainHandler.postDelayed(connectTimeoutRunnable, 20000)
                        try {
                            wearManager.connectDevice(last)
                        } catch (se: SecurityException) {
                            // Log.e(TAG, "SecurityException on auto-reconnect: ${se.message}")
                            isConnecting = false
                            sendToFlutter("STATUS", "Disconnected")
                        } catch (e: Exception) {
                            // Log.e(TAG, "Exception on auto-reconnect: ${e.message}")
                            isConnecting = false
                            sendToFlutter("STATUS", "Disconnected")
                        }
                    }, 3000)
                }
            }

            override fun onBluetoothStatusReceived(device: BluetoothDevice, status: Boolean) {
                // Log.d(TAG, "Bluetooth status: $status")
                sendToFlutter("BLUETOOTH_STATUS", status)
            }
        })
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Individual data callbacks (v3.0.5 add*Callback pattern)
    // ═══════════════════════════════════════════════════════════════════════════
    private fun registerDataCallbacks() {

        // ── Heart Rate Status ─────────────────────────────────────────────────
        wearManager.addHeartRateStatusCallback { device, status, interval, duration ->
            // Log.d(TAG, "[CB] HR Status: status=$status interval=$interval duration=$duration")
            val map = HashMap<String, Int>()
            map["status"] = status
            map["interval"] = interval
            map["duration"] = duration
            sendToFlutter("HEART_RATE_STATUS", map)
        }

        // ── Heart Rate Max ────────────────────────────────────────────────────
        wearManager.addHeartRateMaxCallback { device, maxHR ->
            // Log.d(TAG, "[CB] HR Max: $maxHR")
            sendToFlutter("HEART_RATE_MAX", maxHR)
        }

        // ── Heart Rate Alarm ──────────────────────────────────────────────────
        wearManager.addHeartRateAlarmCallback { device, threshold, enabled ->
            // Log.d(TAG, "[CB] HR Alarm: threshold=$threshold enabled=$enabled")
            val map = HashMap<String, Any>()
            map["threshold"] = threshold
            map["enabled"] = enabled
            sendToFlutter("HEART_RATE_ALARM", map)
        }

        // ── Body Sport ────────────────────────────────────────────────────────
        wearManager.addBodySportCallback { device, step, calorie, distance ->
            // Log.d(TAG, "[CB] Sport: step=$step calorie=$calorie distance=$distance")
            val map = HashMap<String, Int>()
            map["step"] = step
            map["calorie"] = calorie
            map["distance"] = distance
            sendToFlutter("BODY_SPORT", map)
        }

        // ── Body Health ───────────────────────────────────────────────────────
        wearManager.addBodyHealthCallback { device, heartRate, systolic, diastolic, spo2, stress, temperature1, temperature2, temperature3 ->
            // Log.d(TAG, "[CB] Health: hr=$heartRate sys=$systolic dia=$diastolic spo2=$spo2")
            val map = HashMap<String, Any>()
            map["heartRate"] = heartRate
            map["systolic"] = systolic
            map["diastolic"] = diastolic
            map["spo2"] = spo2
            map["stress"] = stress
            map["temperature1"] = temperature1
            map["temperature2"] = temperature2
            map["temperature3"] = temperature3
            sendToFlutter("BODY_HEALTH", map)

        }

        // ── Body Sport Health ─────────────────────────────────────────────────
        wearManager.addBodySportHealthCallback { device, heartRate, systolic, diastolic, spo2, stress ->
            // Log.d(TAG, "[CB] SportHealth: hr=$heartRate sys=$systolic dia=$diastolic spo2=$spo2 stress=$stress")
            val map = HashMap<String, Int>()
            map["heartRate"] = heartRate
            map["systolic"] = systolic
            map["diastolic"] = diastolic
            map["spo2"] = spo2
            map["stress"] = stress
            sendToFlutter("BODY_SPORT_HEALTH", map)
        }

        // ── Blood Oxygen ──────────────────────────────────────────────────────
        wearManager.addBloodOxygenCallback { device, spo2, timestamp, heartRate, systolic, diastolic ->
            // Log.d(TAG, "[CB] BloodOxygen: spo2=$spo2 hr=$heartRate")
            val map = HashMap<String, Any>()
            map["spo2"] = spo2
            map["timestamp"] = timestamp
            map["heartRate"] = heartRate
            map["systolic"] = systolic
            map["diastolic"] = diastolic
            sendToFlutter("BLOOD_OXYGEN", map)
        }

        // ── Temperature ───────────────────────────────────────────────────────
        wearManager.addTemperatureCallback { device, temp1, temp2, temp3 ->
            // Log.d(TAG, "[CB] Temperature: $temp1 / $temp2 / $temp3")
            val map = HashMap<String, Float>()
            map["temperature1"] = temp1
            map["temperature2"] = temp2
            map["temperature3"] = temp3
            sendToFlutter("TEMPERATURE", map)
        }

        // ── Accelerometer ─────────────────────────────────────────────────────
        wearManager.addAccelerometerCallback { device, x, y, z ->
            val map = HashMap<String, Int>()
            map["x"] = x
            map["y"] = y
            map["z"] = z
            sendToFlutter("ACCELEROMETER", map)
        }

        // ── User Info ─────────────────────────────────────────────────────────
        wearManager.addUserInfoCallback { device, gender, age, height, weight, stepLength ->
            // Log.d(TAG, "[CB] UserInfo: gender=$gender age=$age h=$height w=$weight step=$stepLength")
            val map = HashMap<String, Any>()
            map["gender"] = gender
            map["age"] = age
            map["height"] = height
            map["weight"] = weight
            map["stepLength"] = stepLength
            sendToFlutter("USER_INFO", map)
        }

        // ── Bluetooth Status ──────────────────────────────────────────────────
        wearManager.setBluetoothStatusCallback { device, status ->
            // Log.d(TAG, "[CB] BT Status: $status")
            sendToFlutter("BLUETOOTH_STATUS", status)
        }

        // ── PPG Data ──────────────────────────────────────────────────────────
        wearManager.addPPGDataCallback { device, timestamp, ppgData, heartRate, spo2, systolic, diastolic ->
            // Log.d(TAG, "[CB] PPG: hr=$heartRate spo2=$spo2 samples=${ppgData.size}")
            val map = HashMap<String, Any>()
            map["timestamp"] = timestamp
            map["ppgData"] = ppgData.toList()
            map["heartRate"] = heartRate
            map["spo2"] = spo2
            map["systolic"] = systolic
            map["diastolic"] = diastolic
            sendToFlutter("PPG_DATA", map)
        }

        // ── 3D Sensor Frequency ───────────────────────────────────────────────
        wearManager.addSensor3DFrequencyCallback { device, frequency ->
            // Log.d(TAG, "[CB] 3D Freq: $frequency")
            sendToFlutter("SENSOR_3D_FREQUENCY", frequency)
        }

        // ── 3D Sensor Status ──────────────────────────────────────────────────
        wearManager.addSensor3DStatusCallback { device, enabled ->
            // Log.d(TAG, "[CB] 3D Status: $enabled")
            sendToFlutter("SENSOR_3D_STATUS", enabled)
        }

        // ── 6D Sensor Frequency ───────────────────────────────────────────────
        wearManager.addSensor6DFrequencyCallback { device, frequency ->
            // Log.d(TAG, "[CB] 6D Freq: $frequency")
            sendToFlutter("SENSOR_6D_FREQUENCY", frequency)
        }

        // ── 6D Sensor Raw Data ────────────────────────────────────────────────
        wearManager.addSensor6DRawDataCallback { device, timestamp, accX, accY, accZ, gyroX, gyroY, gyroZ, sampleRate ->
            val map = HashMap<String, Any>()
            map["timestamp"] = timestamp
            map["accX"] = accX
            map["accY"] = accY
            map["accZ"] = accZ
            map["gyroX"] = gyroX
            map["gyroY"] = gyroY
            map["gyroZ"] = gyroZ
            map["sampleRate"] = sampleRate
            sendToFlutter("SENSOR_6D_RAW_DATA", map)
        }

        // ── History: HR Record (auto-chains to fetch HR data) ─────────────────
        wearManager.addHistoryOfHRRecordCallback { device, list ->
            // Range filter — keep only headers within [rangeFromSec, rangeToSec].
            // For unfiltered sync (defaults), this is a no-op.
            val filtered = list.filter { stampInRange(it.stamp) }
            val records = filtered.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["record"] = item.record
                m
            }
            sendToFlutter("HISTORY_HR_RECORD", records)

            if (filtered.isEmpty()) {
                sendToFlutter("HISTORY_HR_DATA", emptyList<Any>())
                sendToFlutter("HISTORY_HR_DATA_DONE", 0)
            } else {
                synchronized(hrDataLock) {
                    pendingHrDataCount = filtered.size
                    accumulatedHrData.clear()
                }
                filtered.forEachIndexed { index, item ->
                    mainHandler.postDelayed({
                        try { wearManager.getHistoryOfHRData(item.stamp) }
                        catch (e: Exception) {
                            synchronized(hrDataLock) {
                                pendingHrDataCount--
                                if (pendingHrDataCount <= 0) {
                                    sendToFlutter("HISTORY_HR_DATA_DONE", accumulatedHrData.size)
                                }
                            }
                        }
                    }, (index * 300L) + 200L)
                }
                mainHandler.postDelayed({
                    synchronized(hrDataLock) {
                        if (pendingHrDataCount > 0) {
                            pendingHrDataCount = 0
                            sendToFlutter("HISTORY_HR_DATA_DONE", accumulatedHrData.size)
                        }
                    }
                }, (filtered.size * 300L) + 30_000L)
            }
        }

        // ── History: HR Data — stream each chunk to Flutter immediately ────────
        wearManager.addHistoryOfHRDataCallback { device, list ->
            // Log.d(TAG, "[CB] History HR Data chunk: ${list.size} entries")
            val chunk = list.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["heartRate"] = item.heartRate
                m
            }
            // ★ Send chunk immediately so UI updates live
            sendToFlutter("HISTORY_HR_DATA_CHUNK", chunk)

            synchronized(hrDataLock) {
                accumulatedHrData.addAll(chunk)
                pendingHrDataCount--
                if (pendingHrDataCount <= 0) {
                    // Log.d(TAG, "[CB] HR Data complete: ${accumulatedHrData.size} total entries")
                    sendToFlutter("HISTORY_HR_DATA_DONE", accumulatedHrData.size)
                }
            }
        }

        // ── History: RR Record (auto-chains to fetch RR data) ─────────────────
        wearManager.addHistoryOfRRRecordCallback { device, list ->
            val filtered = list.filter { stampInRange(it.stamp) }
            val records = filtered.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["record"] = item.record
                m
            }
            sendToFlutter("HISTORY_RR_RECORD", records)

            if (filtered.isEmpty()) {
                sendToFlutter("HISTORY_RR_DATA_DONE", 0)
            } else {
                synchronized(rrDataLock) {
                    pendingRrDataCount = filtered.size
                    accumulatedRrData.clear()
                }
                filtered.forEachIndexed { index, item ->
                    mainHandler.postDelayed({
                        try { wearManager.getHistoryOfRRData(item.stamp) }
                        catch (e: Exception) {
                            synchronized(rrDataLock) {
                                pendingRrDataCount--
                                if (pendingRrDataCount <= 0) {
                                    sendToFlutter("HISTORY_RR_DATA_DONE", accumulatedRrData.size)
                                }
                            }
                        }
                    }, (index * 300L) + 200L)
                }
                mainHandler.postDelayed({
                    synchronized(rrDataLock) {
                        if (pendingRrDataCount > 0) {
                            pendingRrDataCount = 0
                            sendToFlutter("HISTORY_RR_DATA_DONE", accumulatedRrData.size)
                        }
                    }
                }, (filtered.size * 300L) + 30_000L)
            }
        }

        // ── History: RR Data — stream each chunk to Flutter immediately ───────
        wearManager.addHistoryOfRRDataCallback { device, list ->
            // Log.d(TAG, "[CB] History RR Data chunk: ${list.size} entries")
            val chunk = list.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                // SDK names field `respiratoryRate` but per SDK changelog this actually
                // carries the R-R interval value. Forward raw; Flutter side labels as `value`.
                m["value"] = item.respiratoryRate
                m
            }
            sendToFlutter("HISTORY_RR_DATA_CHUNK", chunk)

            synchronized(rrDataLock) {
                accumulatedRrData.addAll(chunk)
                pendingRrDataCount--
                if (pendingRrDataCount <= 0) {
                    // Log.d(TAG, "[CB] RR Data complete: ${accumulatedRrData.size} total entries")
                    sendToFlutter("HISTORY_RR_DATA_DONE", accumulatedRrData.size)
                }
            }
        }

        // ── Sleep History ─────────────────────────────────────────────────────
        wearManager.addHistoryOfSleepCallback { device, list ->
            // Log.d(TAG, "[CB-SLEEP] callback fired! list.size=${list.size}")
            val records = list.map { item ->
                val m = HashMap<String, Any>()
                m["utc"] = item.utc
                // Normalize actions to ArrayList<Int> regardless of SDK return type
                // so the Flutter Platform Channel encodes it as a plain List, not TypedData
                val actionsInt: ArrayList<Int> = when (val a = item.actions) {
                    is IntArray  -> ArrayList(a.toList())
                    is ByteArray -> { val l = ArrayList<Int>(a.size); a.forEach { b: Byte -> l.add(b.toInt() and 0xFF) }; l }
                    is List<*>   -> { val l = ArrayList<Int>(a.size); a.forEach { e: Any? -> l.add((e as? Number)?.toInt() ?: 0) }; l }
                    else         -> ArrayList()
                }
                // Log.d(TAG, "[CB-SLEEP] utc=${item.utc}  actions=${actionsInt.size}  first5=${actionsInt.take(5)}")
                m["actions"] = actionsInt
                m
            }
            sendToFlutter("HISTORY_SLEEP", records)
        }

        // ── Custom Data ───────────────────────────────────────────────────────
        wearManager.setCustomDataReceivedCallback { device, data ->
            // Log.d(TAG, "[CB] Custom Data: ${data.size} bytes")
            sendToFlutter("CUSTOM_DATA", data.toList())
        }
    }
}
