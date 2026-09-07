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
            val contentResolver = context.contentResolver
            val inputStream = contentResolver.openInputStream(sourceUri) ?: return@withContext null

            val originalBitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()

            if (originalBitmap == null) return@withContext null

            val fileName = "split_qr_${UUID.randomUUID()}.jpg"
            val destFile = File(qrDirectory, fileName)

            FileOutputStream(destFile).use { out ->
                originalBitmap.compress(Bitmap.CompressFormat.JPEG, 92, out)
            }

            destFile.absolutePath
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
