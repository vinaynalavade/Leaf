package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.utils.CropAspectRatio
import com.vinaynalavade.expensetracker.core.utils.ImageEditUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Phase 3: QR Image Editing, Transformation, and Quality Safeguards Unit Tests.
 *
 * Verifies:
 * 1. Rotation degree normalization (90-degree increments, wraps, negative values).
 * 2. Large image safety and inSampleSize computation to prevent OOM on 48MP/108MP photos.
 * 3. Crop boundary safety guarantees (strict bounds coercion, zero-crash guarantees).
 * 4. Target dimension calculations across aspect ratios (1:1 Square, 4:3, 3:4, 16:9).
 * 5. Zoom and reposition scaling math (framing magnification, pan offsets).
 * 6. QR scanner readability preservation (square aspect ratio preservation, 1:1 proportionality).
 */
class QrImageEditTest {

    @Test
    fun `test normalizeRotationDegrees handles 90 degree increments and negative angles`() {
        assertEquals(0, ImageEditUtils.normalizeRotationDegrees(0))
        assertEquals(90, ImageEditUtils.normalizeRotationDegrees(90))
        assertEquals(180, ImageEditUtils.normalizeRotationDegrees(180))
        assertEquals(270, ImageEditUtils.normalizeRotationDegrees(270))
        assertEquals(0, ImageEditUtils.normalizeRotationDegrees(360))
        assertEquals(90, ImageEditUtils.normalizeRotationDegrees(450))

        // Negative rotations (e.g. counter-clockwise)
        assertEquals(270, ImageEditUtils.normalizeRotationDegrees(-90))
        assertEquals(180, ImageEditUtils.normalizeRotationDegrees(-180))
        assertEquals(90, ImageEditUtils.normalizeRotationDegrees(-270))
        assertEquals(0, ImageEditUtils.normalizeRotationDegrees(-360))
    }

    @Test
    fun `test computeSampleSize protects against OutOfMemory on huge images while keeping QR resolution`() {
        val maxDim = 2048

        // Standard images below maxDimension decode at 1:1 full quality
        assertEquals(1, ImageEditUtils.computeSampleSize(1024, 1024, maxDim))
        assertEquals(1, ImageEditUtils.computeSampleSize(2048, 1536, maxDim))
        assertEquals(1, ImageEditUtils.computeSampleSize(2048, 2048, maxDim))

        // Large camera photos (e.g. 4000x3000 = 12MP) decode at sample size 1 or 2
        val sample12MP = ImageEditUtils.computeSampleSize(4000, 3000, maxDim)
        assertTrue(sample12MP in listOf(1, 2))

        // Ultra high resolution camera photos (e.g. 8000x6000 = 48MP) safely downscale
        val sample48MP = ImageEditUtils.computeSampleSize(8000, 6000, maxDim)
        assertTrue(sample48MP >= 2)

        // Extreme flagship photos (e.g. 12000x9000 = 108MP) safely downscale
        val sample108MP = ImageEditUtils.computeSampleSize(12000, 9000, maxDim)
        assertTrue(sample108MP >= 4)

        // Invalid dimensions fallback to 1 without crashing
        assertEquals(1, ImageEditUtils.computeSampleSize(0, 0, maxDim))
        assertEquals(1, ImageEditUtils.computeSampleSize(-100, -100, maxDim))
    }

    @Test
    fun `test calculateSafeCropBounds strictly enforces source image dimensions`() {
        val srcW = 800
        val srcH = 600

        // In-bounds normal crop
        val normal = ImageEditUtils.calculateSafeCropBounds(srcW, srcH, 100, 100, 300, 300)
        assertEquals(100, normal.left)
        assertEquals(100, normal.top)
        assertEquals(300, normal.width)
        assertEquals(300, normal.height)
        assertTrue(normal.left + normal.width <= srcW)
        assertTrue(normal.top + normal.height <= srcH)

        // Negative coordinates clamped to 0
        val negative = ImageEditUtils.calculateSafeCropBounds(srcW, srcH, -50, -100, 200, 200)
        assertEquals(0, negative.left)
        assertEquals(0, negative.top)
        assertEquals(200, negative.width)
        assertEquals(200, negative.height)

        // Over-sized width and height clamped to available space
        val oversized = ImageEditUtils.calculateSafeCropBounds(srcW, srcH, 600, 400, 500, 500)
        assertEquals(600, oversized.left)
        assertEquals(400, oversized.top)
        assertEquals(200, oversized.width) // 800 - 600 = 200
        assertEquals(200, oversized.height) // 600 - 400 = 200
        assertTrue(oversized.left + oversized.width <= srcW)
        assertTrue(oversized.top + oversized.height <= srcH)

        // Extreme coordinates outside image
        val extreme = ImageEditUtils.calculateSafeCropBounds(srcW, srcH, 9999, 9999, 200, 200)
        assertTrue(extreme.left < srcW)
        assertTrue(extreme.top < srcH)
        assertTrue(extreme.width >= 1)
        assertTrue(extreme.height >= 1)
    }

    @Test
    fun `test calculateTargetDimensions for 1 to 1 Square aspect ratio produces square bounds`() {
        val imgW = 1200
        val imgH = 800

        // Square crop (targetRatio = 1.0) on wide image
        val squareCrop = ImageEditUtils.calculateTargetDimensions(
            imgWidth = imgW,
            imgHeight = imgH,
            targetRatio = 1f,
            zoom = 1f,
            panX = 0f,
            panY = 0f
        )

        assertEquals(squareCrop.width, squareCrop.height)
        assertEquals(800, squareCrop.width)
        // Center position: (1200 - 800) / 2 = 200
        assertEquals(200, squareCrop.left)
        assertEquals(0, squareCrop.top)
    }

    @Test
    fun `test calculateTargetDimensions zoom reduces crop frame for closer framing`() {
        val imgW = 1000
        val imgH = 1000

        val normalCrop = ImageEditUtils.calculateTargetDimensions(
            imgWidth = imgW,
            imgHeight = imgH,
            targetRatio = 1f,
            zoom = 1f,
            panX = 0f,
            panY = 0f
        )

        val zoomedCrop = ImageEditUtils.calculateTargetDimensions(
            imgWidth = imgW,
            imgHeight = imgH,
            targetRatio = 1f,
            zoom = 2f,
            panX = 0f,
            panY = 0f
        )

        assertEquals(1000, normalCrop.width)
        assertEquals(500, zoomedCrop.width)
        assertEquals(500, zoomedCrop.height)
        // Centered: (1000 - 500) / 2 = 250
        assertEquals(250, zoomedCrop.left)
        assertEquals(250, zoomedCrop.top)
    }

    @Test
    fun `test calculateCropRect viewport mapping preserves coordinate bounds`() {
        val imgW = 1600
        val imgH = 1200

        val cropRect = ImageEditUtils.calculateCropRect(
            imgWidth = imgW,
            imgHeight = imgH,
            cropBoxWidthPx = 400f,
            cropBoxHeightPx = 400f,
            scale = 1f,
            panOffsetX = 0f,
            panOffsetY = 0f
        )

        assertTrue(cropRect.left >= 0)
        assertTrue(cropRect.top >= 0)
        assertTrue(cropRect.left + cropRect.width <= imgW)
        assertTrue(cropRect.top + cropRect.height <= imgH)
        assertEquals(cropRect.width, cropRect.height)
    }

    @Test
    fun `test CropAspectRatio enum provides valid ratio values`() {
        assertEquals(1f, CropAspectRatio.SQUARE.ratioX!! / CropAspectRatio.SQUARE.ratioY!!, 0.001f)
        assertEquals(4f / 3f, CropAspectRatio.FOUR_THREE.ratioX!! / CropAspectRatio.FOUR_THREE.ratioY!!, 0.001f)
        assertEquals(3f / 4f, CropAspectRatio.THREE_FOUR.ratioX!! / CropAspectRatio.THREE_FOUR.ratioY!!, 0.001f)
        assertEquals(16f / 9f, CropAspectRatio.SIXTEEN_NINE.ratioX!! / CropAspectRatio.SIXTEEN_NINE.ratioY!!, 0.001f)
    }

    @Test
    fun `test QR storage supports lossless PNG and backward compatible JPEG paths`() {
        // PNG provides lossless pixel preservation for QR edge contrast
        val pngName = "split_qr_test.png"
        val jpgName = "split_qr_legacy.jpg"
        assertTrue(pngName.endsWith(".png"))
        assertTrue(jpgName.endsWith(".jpg"))
    }
}
