package com.vinaynalavade.expensetracker.core.storage

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/**
 * Manages secure local file storage, retrieval, and sharing of uploaded UPI QR code images.
 */
class SplitQrStorageManager(private val context: Context) {

    private val qrDirectory: File by lazy {
        File(context.filesDir, "split_qrs").apply {
            if (!exists()) {
                mkdirs()
            }
        }
    }

    /**
     * Saves an image from a content Uri into internal private storage.
     * Returns the absolute path of the saved file, or null on failure.
     */
    suspend fun saveQrImage(sourceUri: Uri): String? = withContext(Dispatchers.IO) {
        try {
            val bitmap = decodeBitmapFromUri(sourceUri, maxDimension = 2048) ?: return@withContext null
            saveQrBitmap(bitmap)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Saves a processed Bitmap directly into internal private storage.
     * Uses lossless PNG encoding (100% quality) to ensure mathematically perfect contrast,
     * zero compression ringing/artifacts, and maximum readability for all UPI and QR scanners.
     */
    suspend fun saveQrBitmap(bitmap: Bitmap): String? = withContext(Dispatchers.IO) {
        try {
            val fileName = "split_qr_${UUID.randomUUID()}.png"
            val destFile = File(qrDirectory, fileName)

            FileOutputStream(destFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }

            destFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Safely decodes a bitmap from a content Uri with inSampleSize scaling
     * to avoid OutOfMemoryError on large camera photos while preserving high resolution.
     */
    suspend fun decodeBitmapFromUri(sourceUri: Uri, maxDimension: Int = 2048): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val contentResolver = context.contentResolver

            // 1. Decode bounds only
            val boundsOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            contentResolver.openInputStream(sourceUri)?.use { stream ->
                BitmapFactory.decodeStream(stream, null, boundsOptions)
            } ?: return@withContext null

            if (boundsOptions.outWidth <= 0 || boundsOptions.outHeight <= 0) {
                return@withContext null
            }

            // 2. Compute sample size so max dimension is bounded by maxDimension
            var inSampleSize = 1
            val maxOriginalDim = maxOf(boundsOptions.outWidth, boundsOptions.outHeight)
            while ((maxOriginalDim / (inSampleSize * 2)) >= maxDimension) {
                inSampleSize *= 2
            }

            // 3. Decode scaled bitmap
            val decodeOptions = BitmapFactory.Options().apply {
                this.inSampleSize = inSampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            contentResolver.openInputStream(sourceUri)?.use { stream ->
                BitmapFactory.decodeStream(stream, null, decodeOptions)
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Loads a stored QR image as an Android Bitmap directly for editing or processing.
     */
    suspend fun loadAndroidBitmap(filePath: String?): Bitmap? = withContext(Dispatchers.IO) {
        if (filePath.isNullOrBlank()) return@withContext null
        try {
            val file = File(filePath)
            if (file.exists()) {
                BitmapFactory.decodeFile(file.absolutePath)
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Deletes a stored QR image file.
     */
    suspend fun deleteQrImage(filePath: String?) = withContext(Dispatchers.IO) {
        if (filePath.isNullOrBlank()) return@withContext
        try {
            val file = File(filePath)
            if (file.exists() && file.parentFile?.canonicalPath == qrDirectory.canonicalPath) {
                file.delete()
            }
        } catch (_: Exception) {
            // Ignore deletion errors
        }
    }

    /**
     * Obtains a secure FileProvider Uri for external sharing (e.g. to WhatsApp).
     */
    fun getShareableUri(filePath: String?): Uri? {
        if (filePath.isNullOrBlank()) return null
        return try {
            val file = File(filePath)
            if (file.exists()) {
                FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    file
                )
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Loads a stored QR bitmap asynchronously for Compose display.
     */
    suspend fun loadQrBitmap(filePath: String?): ImageBitmap? = withContext(Dispatchers.IO) {
        if (filePath.isNullOrBlank()) return@withContext null
        try {
            val file = File(filePath)
            if (file.exists()) {
                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                bitmap?.asImageBitmap()
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }
}
