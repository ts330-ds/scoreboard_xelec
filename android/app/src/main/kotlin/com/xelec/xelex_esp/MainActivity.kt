package com.xelec.xelex_esp

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import com.android.chileaf.WearManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val TAG = "MainActivity"
    private val METHOD_CHANNEL = "com.example.cl800/sdk_methods"
    private val EVENT_CHANNEL = "com.example.cl800/heartrate_stream"

    private lateinit var chileafHandler: ChileafWearHandler

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Initialize SDK handlers ─────────────────────────────────────
        chileafHandler = ChileafWearHandler(this, WearManager.getInstance(this))
        chileafHandler.init()

        // ── Event Channel ───────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    chileafHandler.dataSink = events
                }
                override fun onCancel(arguments: Any?) {
                    chileafHandler.dataSink = null
                }
            })

        // ── Method Channel ──────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler @androidx.annotation.RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT) { call, result ->
                when (call.method) {

                    "startScan" -> {
                        Log.d(TAG, ">>> startScan called")
                        if (!isBluetoothReady()) {
                            result.error("BLUETOOTH_OFF", "Bluetooth is disabled", null)
                            return@setMethodCallHandler
                        }
                        if (!isLocationEnabled()) {
                            result.error("LOCATION_OFF", "Location is disabled", null)
                            try {
                                startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                            } catch (e: Exception) {}
                            return@setMethodCallHandler
                        }
                        try {
                            chileafHandler.startScan()
                            result.success("Scan Started")
                        } catch (se: SecurityException) {
                            Log.e(TAG, "BLUETOOTH_SCAN permission missing: ${se.message}")
                            result.error("PERMISSION_DENIED", "BLUETOOTH_SCAN permission not granted", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "startScan failed: ${e.message}")
                            result.error("SCAN_FAILED", e.message, null)
                        }
                    }

                    "stopScan" -> {
                        chileafHandler.stopScan()
                        result.success("Scan Stopped")
                    }

                    "connectToDevice" -> {
                        val args = call.arguments as? Map<*, *>
                        val address = args?.get("uuid") as? String
                        if (address.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "address missing", null)
                            return@setMethodCallHandler
                        }
                        if (chileafHandler.connectToDevice(address)) {
                            result.success("Connecting...")
                        } else {
                            result.error("NOT_FOUND", "Device not found: $address", null)
                        }
                    }

                    "disconnect" -> {
                        chileafHandler.disconnect()
                        result.success("Disconnect Command Sent")
                    }

                    "syncAllHistory" -> {
                        if (!chileafHandler.isDeviceConnected) {
                            result.error("NOT_CONNECTED", "No device connected", null)
                            return@setMethodCallHandler
                        }
                        chileafHandler.syncAllHistory()
                        result.success("History sync started")
                    }

                    "syncHistorySingleRecord" -> {
                        val args = call.arguments as? Map<*, *>
                        val stamp = (args?.get("stamp") as? Long) ?: 0L
                        if (!chileafHandler.isDeviceConnected) {
                            result.error("NOT_CONNECTED", "No device connected", null)
                            return@setMethodCallHandler
                        }
                        chileafHandler.syncHistorySingleRecord(stamp)
                        result.success("Single record sync started")
                    }

                    "openBluetoothSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                            } else {
                                startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Bluetooth settings open failed: ${e.message}")
                        }
                        result.success("Opening Bluetooth Settings")
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        chileafHandler.destroy()
    }

    private fun isBluetoothReady(): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        if (!adapter.isEnabled) {
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
