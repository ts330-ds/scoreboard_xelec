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

    /**
     * Replays the CURRENT connection state to Flutter. Called from
     * MainActivity.onListen the moment Dart (re)subscribes to the EventChannel —
     * because STATUS:"Connected" is a one-shot event, a fresh Dart engine that
     * attaches after the device is already connected would otherwise never learn
     * it's connected (continuous HR/BATTERY events keep flowing, so the UI shows
     * live data while the connection flags stay false). This closes that gap.
     */
    fun emitCurrentState() {
        if (!wearManager.isConnected) return
        sendToFlutter("STATUS", "Connected")
        val dev = lastConnectedDevice ?: return
        sendToFlutter("LAST_DEVICE_ADDRESS", dev.address ?: "")
        try {
            val name = dev.name
            if (!name.isNullOrEmpty()) sendToFlutter("LAST_DEVICE_NAME", name)
        } catch (e: SecurityException) { /* name needs BLUETOOTH_CONNECT */ }
    }

    // ── RSSI polling ─────────────────────────────────────────────────────────
    private var rssiRunnable: Runnable? = null

    // ── Sequential fetch queue: HR Record → HR Data ────────────────────────────
    private val hrDataLock = Any()
    private val accumulatedHrData = mutableListOf<HashMap<String, Any>>()
    @Volatile private var hrSyncGen = 0L
    private var hrFetchQueue = listOf<Long>()
    private var hrFetchIndex = 0

    // ── Sequential fetch queue: RR Record → RR Data ──────────────────────────
    private val rrDataLock = Any()
    private val accumulatedRrData = mutableListOf<HashMap<String, Any>>()
    @Volatile private var rrSyncGen = 0L
    private var rrFetchQueue = listOf<Long>()
    private var rrFetchIndex = 0

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

    // When true, HR record callback picks only the single latest session (max stamp)
    // instead of applying the rangeFromSec/rangeToSec filter. Reset after use.
    @Volatile private var latestSessionOnly: Boolean = false

    // When true, record callbacks skip the stampInRange filter and fetch ALL
    // records' data. Data-level filter (in HR/RR data callbacks) still applies
    // rangeFromSec/rangeToSec. Used by syncHistoryRange() because a record's
    // stamp is its session-start, not its data timestamps.
    @Volatile private var useSmartFilter: Boolean = false

    // 24 hours — covers any realistic single recording session on the device.
    private val SESSION_LOOKBACK_SEC = 24L * 60L * 60L

    // ── Sync completion tracking ─────────────────────────────────────────────
    // All three streams (HR, RR, Sleep) must complete before we send SYNC_COMPLETE.
    @Volatile private var hrSyncDone = true
    @Volatile private var rrSyncDone = true
    @Volatile private var sleepSyncDone = true

    // ── Per-record timeout tracking (so we can cancel stale timeouts) ────────
    private var hrTimeoutRunnable: Runnable? = null
    private var rrTimeoutRunnable: Runnable? = null

    // Ek record ka data fetch hone ke liye max wait. History: 5s → 25s → 60s.
    // 2-ghante ki session ka ek record hazaron readings rakhta hai; slow device
    // / BLE congestion (khaaskar live session ke turant baad) me 25s me bhi
    // transfer poora na hota tha → record skip → 0 readings → upload fail.
    // Ab 60s. IMPORTANT: ye Flutter ke idle timeout (BleFetchRangeCubit._idleTimeout)
    // se neeche rehna chahiye — ek record ke transfer ke dauraan Flutter ko koi
    // naya chunk nahi milta, isliye uska idle timer is wait ko cut na kar de.
    // Isliye Flutter idle timeout 60s → 90s bump kiya gaya hai (30s margin).
    private val perRecordTimeoutMs = 60_000L

    // HR/RR record callback fallback. Sleep ki tarah HR/RR record callback bhi
    // device ke paas us stream ka data na hone par fire nahi hota → us stream ka
    // *SyncDone false reh jaata → SYNC_COMPLETE atak jaata → Dart 60s idle tail.
    // Ye runnables tab us stream ko done maan lete hain (sirf jab record callback
    // bilkul na aaya ho — *RecordFired flag se guard).
    private var hrRecordTimeoutRunnable: Runnable? = null
    private var rrRecordTimeoutRunnable: Runnable? = null
    @Volatile private var hrRecordFired = false
    @Volatile private var rrRecordFired = false
    private val recordCallbackTimeoutMs = 10_000L

    // Sleep ek one-shot callback hai (HR/RR jaisa per-record chaining nahi).
    // Agar device ke paas sleep data nahi hai to callback fire nahi hota aur
    // sleepSyncDone false reh jaata — SYNC_COMPLETE kabhi nahi jaata aur push
    // Dart ke 30s safety timer pe atak jaata tha. Ye timeout sleep ko force
    // complete karke turant SYNC_COMPLETE allow karta hai.
    private var sleepTimeoutRunnable: Runnable? = null

    // SYNC_COMPLETE ek hi baar bheje — flags multiple raaston se true ho sakte
    // hain (real callback + timeout dono), idempotency guard.
    @Volatile private var syncCompleteSent = false

    private fun fetchNextHr(gen: Long) {
        val currentIndex: Int
        synchronized(hrDataLock) {
            if (hrSyncGen != gen) return
            if (hrFetchIndex >= hrFetchQueue.size) {
                Log.d(TAG, "[HR-DATA] all done — ${accumulatedHrData.size} total entries")
                sendToFlutter("HISTORY_HR_DATA_DONE", accumulatedHrData.size)
                hrSyncDone = true
                checkSyncComplete()
                return
            }
            currentIndex = hrFetchIndex
            val stamp = hrFetchQueue[currentIndex]
            Log.d(TAG, "[HR-DATA] fetching ${currentIndex + 1}/${hrFetchQueue.size} stamp=$stamp")
        }
        val stamp = hrFetchQueue[currentIndex]
        mainHandler.post {
            if (hrSyncGen != gen) return@post
            try {
                wearManager.getHistoryOfHRData(stamp)
            } catch (e: Exception) {
                Log.w(TAG, "[HR-DATA] fetch failed stamp=$stamp: ${e.message}")
                synchronized(hrDataLock) {
                    if (hrSyncGen != gen) return@synchronized
                    hrFetchIndex++
                    fetchNextHr(gen)
                }
            }
        }
        // Per-record timeout (perRecordTimeoutMs): if callback doesn't fire in
        // time, skip this record.
        // Cancel any previous timeout first to avoid stale runnables stacking up.
        hrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        val timeout = Runnable {
            synchronized(hrDataLock) {
                if (hrSyncGen != gen) return@synchronized
                if (hrFetchIndex == currentIndex) {
                    Log.w(TAG, "[HR-DATA] timeout on record stamp=$stamp, skipping")
                    hrFetchIndex++
                    fetchNextHr(gen)
                }
            }
        }
        hrTimeoutRunnable = timeout
        mainHandler.postDelayed(timeout, perRecordTimeoutMs)
    }

    private fun fetchNextRr(gen: Long) {
        val currentIndex: Int
        synchronized(rrDataLock) {
            if (rrSyncGen != gen) return
            if (rrFetchIndex >= rrFetchQueue.size) {
                Log.d(TAG, "[RR-DATA] all done — ${accumulatedRrData.size} total entries")
                sendToFlutter("HISTORY_RR_DATA_DONE", accumulatedRrData.size)
                rrSyncDone = true
                checkSyncComplete()
                return
            }
            currentIndex = rrFetchIndex
            val stamp = rrFetchQueue[currentIndex]
            Log.d(TAG, "[RR-DATA] fetching ${currentIndex + 1}/${rrFetchQueue.size} stamp=$stamp")
        }
        val stamp = rrFetchQueue[currentIndex]
        mainHandler.post {
            if (rrSyncGen != gen) return@post
            try {
                wearManager.getHistoryOfRRData(stamp)
            } catch (e: Exception) {
                Log.w(TAG, "[RR-DATA] fetch failed stamp=$stamp: ${e.message}")
                synchronized(rrDataLock) {
                    if (rrSyncGen != gen) return@synchronized
                    rrFetchIndex++
                    fetchNextRr(gen)
                }
            }
        }
        // Per-record timeout: cancel previous, then set new.
        rrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        val timeout = Runnable {
            synchronized(rrDataLock) {
                if (rrSyncGen != gen) return@synchronized
                if (rrFetchIndex == currentIndex) {
                    Log.w(TAG, "[RR-DATA] timeout on record stamp=$stamp, skipping")
                    rrFetchIndex++
                    fetchNextRr(gen)
                }
            }
        }
        rrTimeoutRunnable = timeout
        mainHandler.postDelayed(timeout, perRecordTimeoutMs)
    }

    private fun stampInRange(stamp: Long): Boolean {
        val fromWithBuffer = if (rangeFromSec > SESSION_LOOKBACK_SEC) {
            rangeFromSec - SESSION_LOOKBACK_SEC
        } else {
            0L
        }
        return stamp in fromWithBuffer..rangeToSec
    }

    /**
     * Smart filter for range fetch — picks only records whose data coverage
     * could overlap with [rangeFromSec, rangeToSec].
     *
     * A record's data can have timestamps BEFORE or AFTER the record's own
     * stamp. So we apply a 24-hour buffer on BOTH sides:
     * - Include records whose stamp is up to 24h AFTER rangeTo
     *   (data inside may have earlier timestamps)
     * - Include records whose coverage (stamp → next stamp) reaches rangeFrom
     *   (data inside may span into our range)
     *
     * The data-level filter (in HR/RR data callbacks) does the precise
     * timestamp filtering — this is just to reduce BLE traffic.
     *
     * Example: 206 records on device, user picks a 1-hour window →
     * only 2-4 records match instead of all 206.
     */
    private fun <T> smartFilterRecords(
        list: List<T>,
        stampOf: (T) -> Long
    ): List<T> {
        val buffer = SESSION_LOOKBACK_SEC // 24 hours
        val sorted = list.sortedBy { stampOf(it) }
        return sorted.filterIndexed { index, item ->
            val recordStart = stampOf(item)
            val coverEnd = if (index < sorted.size - 1) stampOf(sorted[index + 1]) else Long.MAX_VALUE
            recordStart <= rangeToSec + buffer && coverEnd >= rangeFromSec
        }
    }


    // ── Sync completion ─────────────────────────────────────────────────────
    private fun checkSyncComplete() {
        if (syncCompleteSent) return
        if (hrSyncDone && rrSyncDone && sleepSyncDone) {
            syncCompleteSent = true
            sleepTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            sleepTimeoutRunnable = null
            Log.d(TAG, "[SYNC] All streams complete — sending SYNC_COMPLETE")
            sendToFlutter("SYNC_COMPLETE", "all_done")
            mainHandler.post { startRssiPolling() }
        }
    }

    // getHistoryOfSleep() ke turant baad call karo — agar timeout ke andar sleep
    // callback na aaye to sleep ko done maan ke SYNC_COMPLETE allow karo.
    private fun armSleepTimeout() {
        sleepTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        val r = Runnable {
            if (!sleepSyncDone) {
                Log.w(TAG, "[SLEEP] no callback within timeout — marking sleep done")
                sleepSyncDone = true
                checkSyncComplete()
            }
        }
        sleepTimeoutRunnable = r
        mainHandler.postDelayed(r, 6_000L)
    }

    // getHistoryOfHRRecord() ke turant baad arm karo — agar HR record callback
    // bilkul na aaye (device ke paas HR history nahi) to HR ko done maan ke
    // SYNC_COMPLETE allow karo. hrRecordFired true ho (callback aa gaya, data
    // fetch chal raha) to kuch mat karo — wo fetch chain khud complete hogi.
    private fun armHrRecordTimeout() {
        hrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        val r = Runnable {
            if (!hrRecordFired && !hrSyncDone) {
                Log.w(TAG, "[HR-RECORD] no callback within timeout — marking HR done")
                synchronized(hrDataLock) { accumulatedHrData.clear() }
                sendToFlutter("HISTORY_HR_DATA", emptyList<Any>())
                sendToFlutter("HISTORY_HR_DATA_DONE", 0)
                hrSyncDone = true
                checkSyncComplete()
            }
        }
        hrRecordTimeoutRunnable = r
        mainHandler.postDelayed(r, recordCallbackTimeoutMs)
    }

    // getHistoryOfRRRecord() ke turant baad arm karo (HR jaisa hi).
    private fun armRrRecordTimeout() {
        rrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        val r = Runnable {
            if (!rrRecordFired && !rrSyncDone) {
                Log.w(TAG, "[RR-RECORD] no callback within timeout — marking RR done")
                synchronized(rrDataLock) { accumulatedRrData.clear() }
                sendToFlutter("HISTORY_RR_DATA_DONE", 0)
                rrSyncDone = true
                checkSyncComplete()
            }
        }
        rrRecordTimeoutRunnable = r
        mainHandler.postDelayed(r, recordCallbackTimeoutMs)
    }

    private fun resetSyncFlags() {
        hrSyncDone = false
        rrSyncDone = false
        sleepSyncDone = false
        latestSessionOnly = false
        syncCompleteSent = false
        hrRecordFired = false
        rrRecordFired = false
        hrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        rrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        sleepTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        hrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        rrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        hrTimeoutRunnable = null
        rrTimeoutRunnable = null
        sleepTimeoutRunnable = null
        hrRecordTimeoutRunnable = null
        rrRecordTimeoutRunnable = null
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
        // SDK internal debug logging OFF — true karne pe WearManager + andar ki
        // Nordic BLE library har notification (HR/PPG har few ms) ko logcat me
        // flood karti hai. Diagnose karte waqt hi temporarily true karna.
        wearManager.setDebug(false)
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
        mainHandler.removeCallbacks(scanTimeoutRunnable)
        mainHandler.removeCallbacks(connectTimeoutRunnable)
        mainHandler.postDelayed(connectTimeoutRunnable, 20000)
        wearManager.connectDevice(device)
        return true
    }

    /**
     * Reconnect using a saved MAC address — no prior scan needed.
     * Used when athlete comes back in BLE range after a long time.
     */
    @SuppressLint("MissingPermission")
    fun reconnectByAddress(address: String): Boolean {
        if (wearManager.isConnected || isConnecting) return false
        val adapter = android.bluetooth.BluetoothManager::class.java
            .cast(context.getSystemService(Context.BLUETOOTH_SERVICE))
            ?.adapter ?: return false
        val device = try { adapter.getRemoteDevice(address) } catch (_: Exception) { return false }
        isConnecting = true
        sendToFlutter("STATUS", "Reconnecting...")
        mainHandler.removeCallbacks(connectTimeoutRunnable)
        mainHandler.postDelayed(connectTimeoutRunnable, 20000)
        try {
            wearManager.connectDevice(device)
        } catch (e: Exception) {
            isConnecting = false
            sendToFlutter("STATUS", "Disconnected")
            return false
        }
        return true
    }

    fun disconnect() {
        userInitiatedDisconnect = true
        lastConnectedDevice = null
        stopRssiPolling()
        wearManager.disconnectDevice()

    }

    // ── Device power / reset commands ─────────────────────────────────────────
    /**
     * Powers OFF the connected band. Device disconnects on its own after this;
     * the onDeviceDisconnected callback handles UI state. Returns false if no
     * device is connected.
     */
    fun shutdownDevice(): Boolean {
        if (!wearManager.isConnected) return false
        // Treat like a user-initiated disconnect so auto-reconnect doesn't kick
        // in once the band powers off.
        userInitiatedDisconnect = true
        stopRssiPolling()
        return try {
            wearManager.shutdown()
            true
        } catch (e: Exception) {
            Log.w(TAG, "shutdown failed: ${e.message}")
            false
        }
    }

    /**
     * Factory-resets the connected band. This ERASES all stored settings and
     * history on the device. UTC time + any device settings must be re-applied
     * afterwards. Returns false if no device is connected.
     */
    fun restoreDevice(): Boolean {
        if (!wearManager.isConnected) return false
        return try {
            wearManager.restoration()
            true
        } catch (e: Exception) {
            Log.w(TAG, "restoration failed: ${e.message}")
            false
        }
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
        useSmartFilter = false
        resetSyncFlags()
        stopRssiPolling()
        sendToFlutter("HISTORY_SYNC_START", "syncing")
        try { wearManager.getHistoryOfHRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfHRRecord: ${e.message}") }
        armHrRecordTimeout()
        // Stagger requests so they don't compete in the device's BLE queue
        mainHandler.postDelayed({
            try {
                // Log.d(TAG, ">>> calling getHistoryOfRRRecord()")
                wearManager.getHistoryOfRRRecord()
            } catch (e: Exception) { Log.w(TAG, "getHistoryOfRRRecord: ${e.message}") }
            armRrRecordTimeout()
        }, 1500L)
        mainHandler.postDelayed({
            try {
                // Log.d(TAG, ">>> calling getHistoryOfSleep()")
                wearManager.getHistoryOfSleep()
                // Log.d(TAG, ">>> getHistoryOfSleep() called OK")
            } catch (e: Exception) { Log.e(TAG, "getHistoryOfSleep FAILED: ${e.message}") }
            armSleepTimeout()
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
        var fSec = if (fromMs > 0L) fromMs / 1000L else 0L
        var tSec = if (toMs > 0L) toMs / 1000L else Long.MAX_VALUE
        if (fSec > tSec) { val tmp = fSec; fSec = tSec; tSec = tmp }
        rangeFromSec = fSec
        rangeToSec = tSec
        // Fetch ALL records' data — record stamp = session-start, not data time.
        // Data-level filter in HR/RR data callbacks does the precise filtering.
        useSmartFilter = true
        resetSyncFlags()
        Log.d(TAG, ">>> syncHistoryRange(from=$rangeFromSec to=$rangeToSec sec) useSmartFilter=true")
        stopRssiPolling()
        sendToFlutter("HISTORY_SYNC_START", "syncing")
        try { wearManager.getHistoryOfHRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfHRRecord: ${e.message}") }
        armHrRecordTimeout()
        mainHandler.postDelayed({
            try { wearManager.getHistoryOfRRRecord() } catch (e: Exception) { Log.w(TAG, "getHistoryOfRRRecord: ${e.message}") }
            armRrRecordTimeout()
        }, 1500L)
        mainHandler.postDelayed({
            try { wearManager.getHistoryOfSleep() } catch (e: Exception) { Log.e(TAG, "getHistoryOfSleep FAILED: ${e.message}") }
            armSleepTimeout()
        }, 3000L)
    }

    /**
     * Fetches only the latest HR session from the device.
     * All record headers are retrieved; only the one with the highest stamp
     * triggers a data fetch. Flutter filters the received readings by duration.
     */
    fun syncLatestSession() {
        rangeFromSec = 0L
        rangeToSec = Long.MAX_VALUE
        useSmartFilter = false
        resetSyncFlags()
        latestSessionOnly = true
        // Only HR is fetched for latest session — mark RR & Sleep as done
        rrSyncDone = true
        sleepSyncDone = true
        stopRssiPolling()
        sendToFlutter("HISTORY_SYNC_START", "syncing")
        try {
            wearManager.getHistoryOfHRRecord()
            armHrRecordTimeout()
        } catch (e: Exception) {
            latestSessionOnly = false
            hrSyncDone = true
            checkSyncComplete()
            Log.w(TAG, "syncLatestSession getHistoryOfHRRecord: ${e.message}")
        }
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
            hrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            rrTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            sleepTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            hrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            rrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
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
                try {
                    val name = device.name
                    if (!name.isNullOrEmpty()) sendToFlutter("LAST_DEVICE_NAME", name)
                } catch (e: SecurityException) { /* name needs BLUETOOTH_CONNECT */ }
                startRssiPolling()
                try { wearManager.setUTCTime() } catch (e: Exception) { Log.w(TAG, "setUTCTime: ${e.message}") }

                // ── TEST (temporary): PPG raw stream enable karne ki koshish.
                // PPG callback register hai par device ko kabhi START nahi bola
                // gaya, isliye PPG_DATA aata hi nahi. SDK me explicit setPPGEnabled
                // nahi hai — isliye sabse probable triggers bhej rahe hain. Jo bhi
                // PPG_DATA flow shuru kare wahi sahi enable hai. Test ke baad hata denge.
                try {
                    wearManager.setBloodOxygen(1) // SpO2/PPG measurement start (PPG isi ke saath aata hai)
                    Log.d(TAG, "[PPG-TEST] setBloodOxygen(1) sent")
                } catch (e: Exception) { Log.w(TAG, "[PPG-TEST] setBloodOxygen failed: ${e.message}") }
                try {
                    wearManager.set3DFrequency(25)
                    wearManager.set3DEnabled(true) // raw sensor channel on
                    Log.d(TAG, "[PPG-TEST] set3DEnabled(true) sent")
                } catch (e: Exception) { Log.w(TAG, "[PPG-TEST] set3DEnabled failed: ${e.message}") }
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
            // Record callback aa gaya — fallback timeout cancel karo (ab data
            // fetch chain hi completion handle karegi).
            hrRecordFired = true
            hrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            // latestSessionOnly mode: pick only the record with the highest stamp.
            // Otherwise apply the normal time-range filter.
            val filtered = if (latestSessionOnly) {
                latestSessionOnly = false
                val latest = list.maxByOrNull { it.stamp }
                if (latest != null) listOf(latest) else emptyList()
            } else if (useSmartFilter) {
                smartFilterRecords(list) { it.stamp }
            } else {
                list.filter { stampInRange(it.stamp) }
            }
            Log.d(TAG, "[HR-RECORD] total=${list.size} filtered=${filtered.size} rangeFrom=$rangeFromSec rangeTo=$rangeToSec fetchAll=$useSmartFilter")
            if (list.isNotEmpty()) {
                Log.d(TAG, "[HR-RECORD] first stamp=${list.first().stamp} last stamp=${list.last().stamp}")
            }
            val records = filtered.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["record"] = item.record
                m
            }
            sendToFlutter("HISTORY_HR_RECORD", records)

            if (filtered.isEmpty()) {
                Log.d(TAG, "[HR-RECORD] ⚠ filtered is EMPTY — no HR data will be fetched!")
                synchronized(hrDataLock) { accumulatedHrData.clear() }
                sendToFlutter("HISTORY_HR_DATA", emptyList<Any>())
                sendToFlutter("HISTORY_HR_DATA_DONE", 0)
                hrSyncDone = true
                checkSyncComplete()
            } else {
                val myGen: Long
                synchronized(hrDataLock) {
                    hrSyncGen++
                    myGen = hrSyncGen
                    hrFetchQueue = filtered.map { it.stamp }
                    hrFetchIndex = 0
                    accumulatedHrData.clear()
                }
                fetchNextHr(myGen)
            }
        }

        // ── History: HR Data — filter + stream each chunk to Flutter ─────────
        wearManager.addHistoryOfHRDataCallback { device, list ->
            val raw = list.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["heartRate"] = item.heartRate
                m
            }
            // ★ Data-level filter: drop readings whose stamp falls outside range
            // Stamps can be seconds or milliseconds — normalize to seconds
            val chunk = raw.filter { m ->
                val s = (m["stamp"] as? Number)?.toLong() ?: 0L
                val sSec = if (s > 9999999999L) s / 1000L else s
                sSec in rangeFromSec..rangeToSec
            }
            Log.d(TAG, "[HR-DATA] raw=${raw.size} filtered=${chunk.size} range=$rangeFromSec..$rangeToSec")
            if (chunk.isNotEmpty()) {
                sendToFlutter("HISTORY_HR_DATA_CHUNK", chunk)
            }

            val myGen: Long
            synchronized(hrDataLock) {
                myGen = hrSyncGen
                accumulatedHrData.addAll(chunk)
                hrFetchIndex++
            }
            fetchNextHr(myGen)
        }

        // ── History: RR Record (auto-chains to fetch RR data) ─────────────────
        wearManager.addHistoryOfRRRecordCallback { device, list ->
            // Record callback aa gaya — fallback timeout cancel karo.
            rrRecordFired = true
            rrRecordTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            val filtered = if (useSmartFilter) {
                smartFilterRecords(list) { it.stamp }
            } else {
                list.filter { stampInRange(it.stamp) }
            }
            val records = filtered.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                m["record"] = item.record
                m
            }
            sendToFlutter("HISTORY_RR_RECORD", records)

            if (filtered.isEmpty()) {
                synchronized(rrDataLock) { accumulatedRrData.clear() }
                sendToFlutter("HISTORY_RR_DATA_DONE", 0)
                rrSyncDone = true
                checkSyncComplete()
            } else {
                val myGen: Long
                synchronized(rrDataLock) {
                    rrSyncGen++
                    myGen = rrSyncGen
                    rrFetchQueue = filtered.map { it.stamp }
                    rrFetchIndex = 0
                    accumulatedRrData.clear()
                }
                fetchNextRr(myGen)
            }
        }

        // ── History: RR Data — filter + stream each chunk to Flutter ──────────
        wearManager.addHistoryOfRRDataCallback { device, list ->
            val raw = list.map { item ->
                val m = HashMap<String, Any>()
                m["stamp"] = item.stamp
                // SDK names field `respiratoryRate` but per SDK changelog this actually
                // carries the R-R interval value. Forward raw; Flutter side labels as `value`.
                m["value"] = item.respiratoryRate
                m
            }
            // ★ Data-level filter: drop readings outside range
            // Stamps can be seconds or milliseconds — normalize to seconds
            val chunk = raw.filter { m ->
                val s = (m["stamp"] as? Number)?.toLong() ?: 0L
                val sSec = if (s > 9999999999L) s / 1000L else s
                sSec in rangeFromSec..rangeToSec
            }
            Log.d(TAG, "[RR-DATA] raw=${raw.size} filtered=${chunk.size} range=$rangeFromSec..$rangeToSec")
            if (chunk.isNotEmpty()) {
                sendToFlutter("HISTORY_RR_DATA_CHUNK", chunk)
            }

            val myGen: Long
            synchronized(rrDataLock) {
                myGen = rrSyncGen
                accumulatedRrData.addAll(chunk)
                rrFetchIndex++
            }
            fetchNextRr(myGen)
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
            sleepSyncDone = true
            checkSyncComplete()
        }

        // ── Single Record Info ────────────────────────────────────────────────
        wearManager.addHistoryOfSingleRecordCallback { device, v1, v2, v3, v4 ->
            Log.d(TAG, "[SINGLE-RECORD] v1=$v1 v2=$v2 v3=$v3 v4=$v4")
            val map = HashMap<String, Any>()
            map["v1"] = v1
            map["v2"] = v2
            map["v3"] = v3
            map["v4"] = v4
            sendToFlutter("SINGLE_RECORD_INFO", map)
        }

        // ── Custom Data ───────────────────────────────────────────────────────
        wearManager.setCustomDataReceivedCallback { device, data ->
            // Log.d(TAG, "[CB] Custom Data: ${data.size} bytes")
            sendToFlutter("CUSTOM_DATA", data.toList())
        }
    }
}
