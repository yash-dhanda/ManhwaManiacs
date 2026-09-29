package com.manhwamaniacs.reader

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.HapticFeedbackConstants
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The one `mm/platform` channel. Glass's haptics vocabulary (glass §5.1) lives
 * here: `performHapticFeedback` constants behind SDK checks, plus a one-shot
 * vibration for velocity-scaled impacts. mobile/25 adds `a11y.*`,
 * `audio.isMusicActive` and `gestures.setExclusionRects` to this same channel.
 */
class MmPlatformChannel(messenger: BinaryMessenger, private val activity: Activity) {
    private val channel = MethodChannel(messenger, "mm/platform")

    init {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "haptics.perform" -> result.success(perform(call.argument<String>("pattern")))
            "haptics.oneShot" -> result.success(
                oneShot(call.argument<Int>("ms") ?: 12, call.argument<Int>("amplitude") ?: 128)
            )
            "haptics.systemEnabled" -> result.success(
                Settings.System.getInt(
                    activity.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1
                ) == 1
            )
            else -> result.notImplemented()
        }
    }

    private fun sdk(min: Int) = Build.VERSION.SDK_INT >= min

    /** glass §5.1 table. Returns true when a constant was performed. */
    private fun perform(pattern: String?): Boolean {
        val c: Int = when (pattern) {
            "selection" ->
                if (sdk(34)) HapticFeedbackConstants.SEGMENT_TICK else HapticFeedbackConstants.CLOCK_TICK
            "soft", "light" -> HapticFeedbackConstants.VIRTUAL_KEY
            "medium" -> HapticFeedbackConstants.LONG_PRESS
            "heavy" -> HapticFeedbackConstants.CONTEXT_CLICK
            "rigid" ->
                if (sdk(34)) HapticFeedbackConstants.GESTURE_THRESHOLD_ACTIVATE
                else HapticFeedbackConstants.CONTEXT_CLICK
            "rigidBack" ->
                if (sdk(34)) HapticFeedbackConstants.GESTURE_THRESHOLD_DEACTIVATE
                else HapticFeedbackConstants.VIRTUAL_KEY
            "toggleOn" ->
                if (sdk(34)) HapticFeedbackConstants.TOGGLE_ON else HapticFeedbackConstants.VIRTUAL_KEY
            "toggleOff" ->
                if (sdk(34)) HapticFeedbackConstants.TOGGLE_OFF else return false
            "dragStart" ->
                if (sdk(34)) HapticFeedbackConstants.DRAG_START else HapticFeedbackConstants.VIRTUAL_KEY
            "success" ->
                if (sdk(30)) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY
            "warning" -> HapticFeedbackConstants.KEYBOARD_TAP
            "error" ->
                if (sdk(30)) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS
            else -> return false
        }
        return activity.window.decorView.performHapticFeedback(c)
    }

    private fun oneShot(ms: Int, amplitude: Int): Boolean {
        if (!sdk(26)) return false
        val effect = VibrationEffect.createOneShot(ms.toLong(), amplitude.coerceIn(1, 255))
        if (sdk(31)) {
            val vm = activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator?.vibrate(effect) ?: return false
        } else {
            @Suppress("DEPRECATION")
            val v = activity.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return false
            v.vibrate(effect)
        }
        return true
    }
}
