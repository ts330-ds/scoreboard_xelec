package com.xelec.xelex_esp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service that keeps the BLE connection alive when the app
 * is minimized, a phone call comes in, or the app is swiped away.
 *
 * Shows a persistent notification with live heart-rate data.
 *
 * START_STICKY ensures Android restarts the service if the process is killed.
 */
class BleConnectionService : Service() {

    companion object {
        private const val TAG = "BleConnectionService"
        const val CHANNEL_ID = "ble_hr_channel"
        const val NOTIFICATION_ID = 1001

        // ── Actions ──
        const val ACTION_START = "ACTION_START"
        const val ACTION_UPDATE_HR = "ACTION_UPDATE_HR"
        const val ACTION_UPDATE_STATUS = "ACTION_UPDATE_STATUS"
        const val ACTION_STOP = "ACTION_STOP"

        // ── Extras ──
        const val EXTRA_DEVICE_NAME = "device_name"
        const val EXTRA_HR = "heart_rate"
        const val EXTRA_STATUS = "status"

        /** Call when BLE device connects — starts/updates the foreground notification */
        fun start(context: Context, deviceName: String) {
            val intent = Intent(context, BleConnectionService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_DEVICE_NAME, deviceName)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Call whenever a new heart-rate reading arrives */
        fun updateHeartRate(context: Context, hr: Int) {
            val intent = Intent(context, BleConnectionService::class.java).apply {
                action = ACTION_UPDATE_HR
                putExtra(EXTRA_HR, hr)
            }
            try { context.startService(intent) } catch (e: Exception) {
                Log.w(TAG, "updateHeartRate startService failed: ${e.message}")
            }
        }

        /** Call when connection status changes (e.g. "Reconnecting...") */
        fun updateStatus(context: Context, status: String) {
            val intent = Intent(context, BleConnectionService::class.java).apply {
                action = ACTION_UPDATE_STATUS
                putExtra(EXTRA_STATUS, status)
            }
            try { context.startService(intent) } catch (e: Exception) {
                Log.w(TAG, "updateStatus startService failed: ${e.message}")
            }
        }

        /** Call when user deliberately disconnects — removes notification & stops service */
        fun stop(context: Context) {
            val intent = Intent(context, BleConnectionService::class.java).apply {
                action = ACTION_STOP
            }
            try { context.startService(intent) } catch (e: Exception) {
                Log.w(TAG, "stop startService failed: ${e.message}")
            }
        }
    }

    // ── State ──
    private var currentHR = 0
    private var deviceName = "Watch"
    private var connectionStatus = "Connected"

    // ═════════════════════════════════════════════════════════════════════════════
    // Lifecycle
    // ═════════════════════════════════════════════════════════════════════════════

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {

            ACTION_START -> {
                deviceName = intent.getStringExtra(EXTRA_DEVICE_NAME) ?: "Watch"
                connectionStatus = "Connected"
                currentHR = 0
                startForeground(NOTIFICATION_ID, buildNotification())
                Log.d(TAG, "Foreground service started — device: $deviceName")
            }

            ACTION_UPDATE_HR -> {
                val hr = intent.getIntExtra(EXTRA_HR, 0)
                if (hr > 0) {
                    currentHR = hr
                    refreshNotification()
                }
            }

            ACTION_UPDATE_STATUS -> {
                connectionStatus = intent.getStringExtra(EXTRA_STATUS) ?: "Connected"
                refreshNotification()
                Log.d(TAG, "Status updated: $connectionStatus")
            }

            ACTION_STOP -> {
                Log.d(TAG, "Service stopping (user disconnect)")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        // START_STICKY → Android restarts this service after process kill
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }

    // ═════════════════════════════════════════════════════════════════════════════
    // Notification
    // ═════════════════════════════════════════════════════════════════════════════

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Heart Rate Monitor",
                NotificationManager.IMPORTANCE_LOW   // silent — no sound / vibration
            ).apply {
                description = "Shows live heart rate from connected watch"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        // ── Title based on connection status ──
        val title = when (connectionStatus) {
            "Connected" -> "\u2764\uFE0F $deviceName Connected"
            "Reconnecting..." -> "\uD83D\uDD04 Reconnecting to $deviceName..."
            else -> "\u2764\uFE0F $deviceName"
        }

        // ── Body text ──
        val hrText = if (currentHR > 0) "$currentHR bpm" else "Measuring..."
        val body = when (connectionStatus) {
            "Reconnecting..." -> "Last HR: $hrText"
            else -> "Heart Rate: $hrText"
        }

        // ── Tap to open the app ──
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun refreshNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification())
    }
}
