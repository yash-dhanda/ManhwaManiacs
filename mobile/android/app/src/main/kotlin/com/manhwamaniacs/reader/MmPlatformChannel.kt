package com.manhwamaniacs.reader

import android.app.Activity
import android.app.UiModeManager
import android.graphics.Rect
import android.media.AudioManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.HapticFeedbackConstants
import android.view.WindowInsets
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The one `mm/platform` channel. Glass's haptics vocabulary (glass §5.1) lives
 * here: `performHapticFeedback` constants behind SDK checks, plus a one-shot
 * vibration for velocity-scaled impacts. mobile/25 adds `a11y.*`,
 * `audio.isMusicActive` and `gestures.setExclusionRects` to this same channel; mobile/35 adds
 * `display.stableInsets`.
 */
class MmPlatformChannel(messenger: BinaryMessenger, private val activity: Activity) {
    private val channel = MethodChannel(messenger, "mm/platform")

    private var contrastListener: Any? = null

    /** Battery Saver on or off (`power.lowPowerChanged`): Glass drops its refraction and blur to tinted solid while it is on. */
    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            channel.invokeMethod("power.lowPowerChanged", mapOf("value" to lowPower()))
        }
    }

    private fun lowPower(): Boolean =
        (activity.getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isPowerSaveMode ?: false

    init {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
        registerContrastListener()
        activity.registerReceiver(powerReceiver, IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED))
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        runCatching { activity.unregisterReceiver(powerReceiver) }
        if (Build.VERSION.SDK_INT >= 34) {
            (contrastListener as? UiModeManager.ContrastChangeListener)?.let {
                (activity.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)?.removeContrastChangeListener(it)
            }
        }
        contrastListener = null
    }

    /** Android 14+: tell Dart when the user moves the system contrast slider (`a11y.contrastLevelChanged`). */
    private fun registerContrastListener() {
        if (Build.VERSION.SDK_INT < 34) return
        val ui = activity.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager ?: return
        val listener = UiModeManager.ContrastChangeListener { level ->
            channel.invokeMethod("a11y.contrastLevelChanged", mapOf("value" to level.toDouble()))
        }
        ui.addContrastChangeListener(activity.mainExecutor, listener)
        contrastListener = listener
    }

    /** `[[left, top, width, height], ...]` in logical px to the system gesture exclusion list (API 29+). */
    private fun setExclusionRects(rects: List<*>?) {
        if (Build.VERSION.SDK_INT < 29) return
        val d = activity.resources.displayMetrics.density
        val out = (rects ?: emptyList<Any>()).mapNotNull { r ->
            val v = (r as? List<*>)?.mapNotNull { (it as? Number)?.toDouble() }
            if (v == null || v.size < 4) null
            else Rect(
                (v[0] * d).toInt(), (v[1] * d).toInt(),
                ((v[0] + v[2]) * d).toInt(), ((v[1] + v[3]) * d).toInt(),
            )
        }
        activity.window.decorView.systemGestureExclusionRects = out
    }

    /**
     * The stable system-bar and cutout insets in logical px (glass 15.3 `display.stableInsets`): what the bars
     * take when shown, even while the reader hides them. API 30+ reads `getInsetsIgnoringVisibility`; API 24-29
     * the deprecated stable insets, raised per side by the display cutout on API 28-29. Null before the window
     * is attached.
     */
    private fun stableInsets(): Map<String, Double>? {
        val root = activity.window.decorView.rootWindowInsets ?: return null
        val d = activity.resources.displayMetrics.density.toDouble()
        val sides: IntArray = if (Build.VERSION.SDK_INT >= 30) {
            val i = root.getInsetsIgnoringVisibility(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            intArrayOf(i.left, i.top, i.right, i.bottom)
        } else {
            @Suppress("DEPRECATION")
            val s = intArrayOf(root.stableInsetLeft, root.stableInsetTop, root.stableInsetRight, root.stableInsetBottom)
            val c = if (Build.VERSION.SDK_INT >= 28) root.displayCutout else null
            if (c != null) {
                s[0] = maxOf(s[0], c.safeInsetLeft)
                s[1] = maxOf(s[1], c.safeInsetTop)
                s[2] = maxOf(s[2], c.safeInsetRight)
                s[3] = maxOf(s[3], c.safeInsetBottom)
            }
            s
        }
        return mapOf("left" to sides[0] / d, "top" to sides[1] / d, "right" to sides[2] / d, "bottom" to sides[3] / d)
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
            // Android has no Reduce Transparency signal (iOS answers this one).
            "a11y.reduceTransparency" -> result.success(false)
            "a11y.contrastLevel" -> result.success(
                if (Build.VERSION.SDK_INT >= 34) {
                    (activity.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)
                        ?.contrast?.toDouble() ?: 0.0
                } else 0.0
            )
            "power.lowPower" -> result.success(lowPower())
            "audio.isMusicActive" -> result.success(
                (activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager)?.isMusicActive ?: false
            )
            "display.stableInsets" -> result.success(stableInsets())
            "gestures.setExclusionRects" -> {
                setExclusionRects(call.argument<List<*>>("rects"))
                result.success(null)
            }
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
