package com.vinaynalavade.expensetracker.core.utils

import android.graphics.Bitmap
import android.graphics.Matrix
import kotlin.math.roundToInt

enum class CropAspectRatio(val label: String, val ratioX: Float?, val ratioY: Float?) {
    SQUARE("1:1", 1f, 1f),
    ORIGINAL("Original", null, null),
    FOUR_THREE("4:3", 4f, 3f),
    THREE_FOUR("3:4", 3f, 4f),
    SIXTEEN_NINE("16:9", 16f, 9f)
}

data class CropRect(
    val left: Int,
    val top: Int,
    val width: Int,
    val height: Int
)

object ImageEditUtils {

    /**
     * Normalizes rotation degrees to standard {0, 90, 180, 270}.
     */
    fun normalizeRotationDegrees(degrees: Int): Int {
        return ((degrees % 360) + 360) % 360
    }

    /**
     * Computes the power-of-two inSampleSize needed to safely decode large images
     * without exceeding maxDimension, preventing OutOfMemoryError while keeping resolution high.
     */
    fun computeSampleSize(originalWidth: Int, originalHeight: Int, maxDimension: Int): Int {
        if (originalWidth <= 0 || originalHeight <= 0 || maxDimension <= 0) return 1
        var inSampleSize = 1
        val maxOriginalDim = maxOf(originalWidth, originalHeight)
        while ((maxOriginalDim / (inSampleSize * 2)) >= maxDimension) {
            inSampleSize *= 2
        }
        return inSampleSize
    }

    /**
     * Validates and coerces crop boundaries safely within image dimensions.
     */
    fun calculateSafeCropBounds(sourceWidth: Int, sourceHeight: Int, left: Int, top: Int, width: Int, height: Int): CropRect {
        val safeLeft = left.coerceIn(0, (sourceWidth - 1).coerceAtLeast(0))
        val safeTop = top.coerceIn(0, (sourceHeight - 1).coerceAtLeast(0))
        val safeWidth = width.coerceIn(1, sourceWidth - safeLeft)
        val safeHeight = height.coerceIn(1, sourceHeight - safeTop)
        return CropRect(safeLeft, safeTop, safeWidth, safeHeight)
    }

    /**
     * Calculates crop rectangle for an aspect ratio, zoom level, and pan offsets.
     */
    fun calculateTargetDimensions(
        imgWidth: Int,
        imgHeight: Int,
        targetRatio: Float,
        zoom: Float,
        panX: Float,
        panY: Float
    ): CropRect {
        val (baseCropW, baseCropH) = if (imgWidth.toFloat() / imgHeight.toFloat() > targetRatio) {
            val h = imgHeight.toFloat()
            val w = h * targetRatio
            Pair(w, h)
        } else {
            val w = imgWidth.toFloat()
            val h = w / targetRatio
            Pair(w, h)
        }

        val effectiveZoom = zoom.coerceIn(0.5f, 5f)
        val finalCropW = (baseCropW / effectiveZoom).coerceIn(1f, imgWidth.toFloat())
        val finalCropH = (baseCropH / effectiveZoom).coerceIn(1f, imgHeight.toFloat())

        val panFactor = (imgWidth.toFloat() / 800f).coerceAtLeast(1f)
        val centerImgX = imgWidth / 2f - (panX * panFactor / effectiveZoom)
        val centerImgY = imgHeight / 2f - (panY * panFactor / effectiveZoom)

        val left = (centerImgX - finalCropW / 2f).toInt()
        val top = (centerImgY - finalCropH / 2f).toInt()
        val width = finalCropW.toInt()
        val height = finalCropH.toInt()

        return calculateSafeCropBounds(imgWidth, imgHeight, left, top, width, height)
    }

    /**
     * Rotates a bitmap by a given number of degrees (e.g. 90, 180, 270).
     * If degrees is 0 or 360, returns the original bitmap without creating a duplicate.
     */
    fun rotateBitmap(source: Bitmap, degrees: Int): Bitmap {
        val normalizedDegrees = normalizeRotationDegrees(degrees)
        if (normalizedDegrees == 0) return source

        val matrix = Matrix().apply {
            postRotate(normalizedDegrees.toFloat())
        }
        return Bitmap.createBitmap(
            source,
            0,
            0,
            source.width,
            source.height,
            matrix,
            true
        )
    }

    /**
     * Crops a region from the source bitmap, safely bounding within valid coordinates.
     */
    fun cropBitmap(source: Bitmap, left: Int, top: Int, width: Int, height: Int): Bitmap {
        val safeBounds = calculateSafeCropBounds(source.width, source.height, left, top, width, height)
        return Bitmap.createBitmap(source, safeBounds.left, safeBounds.top, safeBounds.width, safeBounds.height)
    }

    /**
     * Calculates the crop rectangle in source bitmap coordinates based on:
     * - source dimensions (imgWidth, imgHeight)
     * - crop viewport dimensions on screen (cropBoxWidthPx, cropBoxHeightPx)
     * - scale applied (scaleFactor relative to image base size)
     * - pan offsets (panOffsetX, panOffsetY) in screen pixels relative to the crop center
     */
    fun calculateCropRect(
        imgWidth: Int,
        imgHeight: Int,
        cropBoxWidthPx: Float,
        cropBoxHeightPx: Float,
        scale: Float,
        panOffsetX: Float,
        panOffsetY: Float
    ): CropRect {
        val effectiveScale = scale.coerceAtLeast(0.001f)

        val srcLeft = (imgWidth / 2f) - (cropBoxWidthPx / (2f * effectiveScale)) - (panOffsetX / effectiveScale)
        val srcTop = (imgHeight / 2f) - (cropBoxHeightPx / (2f * effectiveScale)) - (panOffsetY / effectiveScale)
        val srcWidth = cropBoxWidthPx / effectiveScale
        val srcHeight = cropBoxHeightPx / effectiveScale

        return calculateSafeCropBounds(
            imgWidth,
            imgHeight,
            srcLeft.roundToInt(),
            srcTop.roundToInt(),
            srcWidth.roundToInt(),
            srcHeight.roundToInt()
        )
    }
}
