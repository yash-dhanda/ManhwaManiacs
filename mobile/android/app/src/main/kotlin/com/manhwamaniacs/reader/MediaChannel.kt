package com.manhwamaniacs.reader

import android.app.Activity
import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The `mm/media` channel: saving files into the shared media collections.
 *
 *  - `canSaveImage`: true on Android 10 (API 29) and later, where MediaStore
 *    takes a scoped insert with no permission. Earlier versions would need
 *    WRITE_EXTERNAL_STORAGE, so the Save image button is hidden there.
 *  - `saveImage(bytes, name)`: inserts a PNG into `Pictures/ManhwaManiacs`
 *    with `IS_PENDING = 1`, writes it through `openOutputStream`, then clears
 *    the flag so the gallery sees it only once it is whole.
 *
 * mobile/17 adds `saveDownload` to this same channel.
 */
class MediaChannel(messenger: BinaryMessenger, private val activity: Activity) {
    private val channel = MethodChannel(messenger, "mm/media")

    init {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canSaveImage" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            "saveImage" -> {
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                if (bytes == null || name == null) {
                    result.error("bad_args", "bytes and name are required", null)
                } else {
                    result.success(saveImage(bytes, name))
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Returns true when the PNG is in `Pictures/ManhwaManiacs`. */
    private fun saveImage(bytes: ByteArray, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ManhwaManiacs")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        return try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: throw IllegalStateException("no stream")
            val done = ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
            true
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }
}
