package com.manhwamaniacs.reader

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The `mm/media` channel. `saveDownload` copies a file into MediaStore `Downloads` (API 29+, no
 * permission needed); `sdkInt` tells Dart which export destination applies. mobile/21 adds its
 * share-card method to this same channel.
 */
class MediaChannel(messenger: BinaryMessenger, private val context: Context) {
    private val channel = MethodChannel(messenger, "mm/media")

    init {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
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
            "saveDownload" -> {
                val relativePath = call.argument<String>("relativePath")
                val name = call.argument<String>("name")
                val mime = call.argument<String>("mime")
                val path = call.argument<String>("path")
                if (relativePath == null || name == null || mime == null || path == null) {
                    result.error("bad_args", "saveDownload needs relativePath, name, mime and path", null)
                    return
                }
                try {
                    result.success(saveDownload(relativePath, name, mime, path))
                } catch (e: Exception) {
                    result.error("save_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    // Insert with IS_PENDING = 1, stream the bytes through the resolver, then clear the flag so
    // the file only appears in Files once it is whole. Returns the content URI.
    private fun saveDownload(relativePath: String, name: String, mime: String, path: String): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException("MediaStore.Downloads needs API 29")
        }
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("MediaStore refused the insert")
        try {
            resolver.openOutputStream(uri)?.use { out ->
                File(path).inputStream().use { it.copyTo(out) }
            } ?: throw IllegalStateException("No output stream for $uri")
            val done = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        return uri.toString()
    }

    /** Returns true when the PNG is in `Pictures/ManhwaManiacs` (IS_PENDING while writing). */
    private fun saveImage(bytes: ByteArray, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, java.net.URLConnection.guessContentTypeFromName(name) ?: "image/png")
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
