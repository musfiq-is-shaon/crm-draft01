package app.atl.crm

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Creates the default FCM notification channel as soon as the process starts.
 *
 * When the app is killed, Firebase may post a tray notification using
 * [com.google.firebase.messaging.default_notification_channel_id] **before** Flutter runs.
 * If the channel does not exist yet (e.g. first install, data cleared), Android 8+ may drop
 * or downgrade those notifications.
 */
class CrmApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ensureFcmDefaultChannel()
    }

    private fun ensureFcmDefaultChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val id = getString(R.string.default_notification_channel_id)
        val name = getString(R.string.default_notification_channel_name)
        val description = getString(R.string.default_notification_channel_description)
        val importance =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                NotificationManager.IMPORTANCE_MAX
            } else {
                NotificationManager.IMPORTANCE_HIGH
            }
        val channel = NotificationChannel(id, name, importance).apply {
            this.description = description
            enableVibration(true)
            setShowBadge(true)
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }
}
