package app.atl.crm

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "ForceUpdate"
        private const val IMMEDIATE_UPDATE_REQUEST_CODE = 19091
    }

    private lateinit var appUpdateManager: AppUpdateManager
    private val retryHandler = Handler(Looper.getMainLooper())
    private var retryAttempt = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appUpdateManager = AppUpdateManagerFactory.create(this)
        // Enforce update at app start.
        checkForImmediateUpdate()
    }

    override fun onResume() {
        super.onResume()
        // Resume interrupted update flow or re-enforce when still available.
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info ->
                when {
                    info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS -> {
                        startImmediateUpdate(info)
                    }
                    info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                        info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE) -> {
                        startImmediateUpdate(info)
                    }
                }
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to query update state in onResume.", e)
                scheduleRetry()
            }
    }

    override fun onDestroy() {
        retryHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    @Deprecated("Required for FlutterActivity compatibility with Play Core update flow.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != IMMEDIATE_UPDATE_REQUEST_CODE) return
        when (resultCode) {
            RESULT_OK -> {
                // User accepted update flow; Play handles install UI and flow from here.
                retryAttempt = 0
            }
            RESULT_CANCELED -> {
                // Immediate update is mandatory for app usage; retry when canceled.
                Log.w(TAG, "Immediate update canceled by user; retrying.")
                scheduleRetry()
            }
            ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> {
                Log.e(TAG, "Immediate update failed; retrying.")
                scheduleRetry()
            }
            else -> {
                Log.w(TAG, "Unknown update result: $resultCode; retrying.")
                scheduleRetry()
            }
        }
    }

    // Queries Google Play for update availability and starts Immediate flow if allowed.
    private fun checkForImmediateUpdate() {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                    info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                ) {
                    startImmediateUpdate(info)
                } else {
                    retryAttempt = 0
                }
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to check for app update.", e)
                scheduleRetry()
            }
    }

    // Launches full-screen blocking Immediate update UI.
    private fun startImmediateUpdate(info: AppUpdateInfo) {
        runCatching {
            appUpdateManager.startUpdateFlowForResult(
                info,
                this,
                AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE)
                    .setAllowAssetPackDeletion(true)
                    .build(),
                IMMEDIATE_UPDATE_REQUEST_CODE
            )
        }.onFailure { e ->
            Log.e(TAG, "Failed to launch immediate update flow.", e)
            scheduleRetry()
        }
    }

    // Retries with capped exponential backoff.
    private fun scheduleRetry() {
        retryHandler.removeCallbacksAndMessages(null)
        retryAttempt++
        val delayMs = (1000L * (1 shl (retryAttempt - 1))).coerceAtMost(10_000L)
        retryHandler.postDelayed({ checkForImmediateUpdate() }, delayMs)
    }
}
