package com.vinaynalavade.expensetracker.presentation.split.components

import android.graphics.Bitmap
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.RotateRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.draw.clip
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.vinaynalavade.expensetracker.core.utils.CropAspectRatio
import com.vinaynalavade.expensetracker.core.utils.ImageEditUtils
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import kotlin.math.min

@Composable
fun QrImageEditDialog(
    sourceBitmap: Bitmap,
    onDismiss: () -> Unit,
    onSave: (Bitmap) -> Unit
) {
    var rotationDegrees by remember { mutableIntStateOf(0) }
    var selectedAspectRatio by remember { mutableStateOf(CropAspectRatio.SQUARE) }
    var zoomScale by remember { mutableFloatStateOf(1f) }
    var panOffset by remember { mutableStateOf(Offset.Zero) }

    // Derive rotated bitmap for live preview
    val currentRotatedBitmap = remember(sourceBitmap, rotationDegrees) {
        ImageEditUtils.rotateBitmap(sourceBitmap, rotationDegrees)
    }
    val composeImageBitmap = remember(currentRotatedBitmap) {
        currentRotatedBitmap.asImageBitmap()
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = true,
            dismissOnClickOutside = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF0F172A)) // Obsidian dark backdrop
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                // 1. Top Bar: Cancel, Title, and Save/Done
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp, bottom = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.size(48.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Cancel Editing",
                            tint = Color.White
                        )
                    }

                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "Crop & Adjust QR",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "Pinch to zoom • Drag to frame QR code",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            color = Color.White.copy(alpha = 0.7f)
                        )
                    }

                    Button(
                        onClick = {
                            // Compute crop bounds relative to the crop frame and apply
                            // (We use a normalized center crop fallback or calculated exact rect)
                            val finalCropped = applyCrop(
                                bitmap = currentRotatedBitmap,
                                aspectRatio = selectedAspectRatio,
                                zoom = zoomScale,
                                pan = panOffset
                            )
                            onSave(finalCropped)
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary
                        ),
                        shape = PillShape,
                        modifier = Modifier.defaultMinSize(minHeight = 44.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Apply", fontWeight = FontWeight.Bold)
                    }
                }

                // 2. Interactive Viewport & Crop Frame
                BoxWithConstraints(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color.Black)
                        .pointerInput(currentRotatedBitmap) {
                            detectTransformGestures { _, pan, zoom, _ ->
                                zoomScale = (zoomScale * zoom).coerceIn(0.8f, 5f)
                                panOffset = Offset(panOffset.x + pan.x, panOffset.y + pan.y)
                            }
                        },
                    contentAlignment = Alignment.Center
                ) {
                    val density = LocalDensity.current
                    val viewportWidthPx = with(density) { maxWidth.toPx() }
                    val viewportHeightPx = with(density) { maxHeight.toPx() }

                    // Compute Crop Box Dimensions in pixels based on selected aspect ratio
                    val maxCropDim = min(viewportWidthPx, viewportHeightPx) * 0.85f
                    val (cropBoxWidthPx, cropBoxHeightPx) = when (selectedAspectRatio) {
                        CropAspectRatio.SQUARE -> Pair(maxCropDim, maxCropDim)
                        CropAspectRatio.FOUR_THREE -> Pair(maxCropDim, maxCropDim * 3f / 4f)
                        CropAspectRatio.THREE_FOUR -> Pair(maxCropDim * 3f / 4f, maxCropDim)
                        CropAspectRatio.SIXTEEN_NINE -> Pair(maxCropDim, maxCropDim * 9f / 16f)
                        CropAspectRatio.ORIGINAL -> {
                            val imgRatio = currentRotatedBitmap.width.toFloat() / currentRotatedBitmap.height.toFloat()
                            if (imgRatio >= 1f) {
                                Pair(maxCropDim, maxCropDim / imgRatio)
                            } else {
                                Pair(maxCropDim * imgRatio, maxCropDim)
                            }
                        }
                    }

                    // Render Transformable Image
                    Image(
                        bitmap = composeImageBitmap,
                        contentDescription = "QR Image for Cropping",
                        modifier = Modifier
                            .graphicsLayer(
                                scaleX = zoomScale,
                                scaleY = zoomScale,
                                translationX = panOffset.x,
                                translationY = panOffset.y
                            )
                    )

                    // Draw Crop Overlay Scrim, Corner Brackets, and Gridlines
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val canvasW = size.width
                        val canvasH = size.height

                        val cropLeft = (canvasW - cropBoxWidthPx) / 2f
                        val cropTop = (canvasH - cropBoxHeightPx) / 2f
                        val cropRight = cropLeft + cropBoxWidthPx
                        val cropBottom = cropTop + cropBoxHeightPx

                        val scrimColor = Color.Black.copy(alpha = 0.60f)

                        // 4 Scrim Rectangles outside crop box
                        // Top
                        drawRect(color = scrimColor, topLeft = Offset.Zero, size = Size(canvasW, cropTop))
                        // Bottom
                        drawRect(color = scrimColor, topLeft = Offset(0f, cropBottom), size = Size(canvasW, canvasH - cropBottom))
                        // Left
                        drawRect(color = scrimColor, topLeft = Offset(0f, cropTop), size = Size(cropLeft, cropBoxHeightPx))
                        // Right
                        drawRect(color = scrimColor, topLeft = Offset(cropRight, cropTop), size = Size(canvasW - cropRight, cropBoxHeightPx))

                        // Crop Box Outline
                        drawRect(
                            color = Color.White.copy(alpha = 0.9f),
                            topLeft = Offset(cropLeft, cropTop),
                            size = Size(cropBoxWidthPx, cropBoxHeightPx),
                            style = Stroke(width = 2.dp.toPx())
                        )

                        // Rule of Thirds Gridlines inside Crop Box
                        val gridColor = Color.White.copy(alpha = 0.30f)
                        val strokeGrid = Stroke(width = 1.dp.toPx())

                        val thirdW = cropBoxWidthPx / 3f
                        val thirdH = cropBoxHeightPx / 3f

                        // Vertical gridlines
                        drawLine(color = gridColor, start = Offset(cropLeft + thirdW, cropTop), end = Offset(cropLeft + thirdW, cropBottom), strokeWidth = strokeGrid.width)
                        drawLine(color = gridColor, start = Offset(cropLeft + 2 * thirdW, cropTop), end = Offset(cropLeft + 2 * thirdW, cropBottom), strokeWidth = strokeGrid.width)

                        // Horizontal gridlines
                        drawLine(color = gridColor, start = Offset(cropLeft, cropTop + thirdH), end = Offset(cropRight, cropTop + thirdH), strokeWidth = strokeGrid.width)
                        drawLine(color = gridColor, start = Offset(cropLeft, cropTop + 2 * thirdH), end = Offset(cropRight, cropTop + 2 * thirdH), strokeWidth = strokeGrid.width)

                        // Corner Brackets for tactile focus
                        val bracketLen = 18.dp.toPx()
                        val bracketWidth = 3.5.dp.toPx()
                        val bracketColor = Color(0xFF10B981) // Emerald accent

                        // Top-Left
                        drawLine(bracketColor, Offset(cropLeft - 1f, cropTop), Offset(cropLeft + bracketLen, cropTop), bracketWidth)
                        drawLine(bracketColor, Offset(cropLeft, cropTop - 1f), Offset(cropLeft, cropTop + bracketLen), bracketWidth)

                        // Top-Right
                        drawLine(bracketColor, Offset(cropRight + 1f, cropTop), Offset(cropRight - bracketLen, cropTop), bracketWidth)
                        drawLine(bracketColor, Offset(cropRight, cropTop - 1f), Offset(cropRight, cropTop + bracketLen), bracketWidth)

                        // Bottom-Left
                        drawLine(bracketColor, Offset(cropLeft - 1f, cropBottom), Offset(cropLeft + bracketLen, cropBottom), bracketWidth)
                        drawLine(bracketColor, Offset(cropLeft, cropBottom + 1f), Offset(cropLeft, cropBottom - bracketLen), bracketWidth)

                        // Bottom-Right
                        drawLine(bracketColor, Offset(cropRight + 1f, cropBottom), Offset(cropRight - bracketLen, cropBottom), bracketWidth)
                        drawLine(bracketColor, Offset(cropRight, cropBottom + 1f), Offset(cropRight, cropBottom - bracketLen), bracketWidth)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // 3. Aspect Ratio Selection Chips
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Aspect Ratio:",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White.copy(alpha = 0.7f),
                        modifier = Modifier.padding(end = 4.dp)
                    )

                    CropAspectRatio.entries.forEach { ratio ->
                        FilterChip(
                            selected = selectedAspectRatio == ratio,
                            onClick = { selectedAspectRatio = ratio },
                            label = {
                                Text(
                                    text = ratio.label,
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = if (selectedAspectRatio == ratio) FontWeight.Bold else FontWeight.Normal
                                )
                            },
                            shape = PillShape,
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primary,
                                selectedLabelColor = MaterialTheme.colorScheme.onPrimary,
                                containerColor = Color.White.copy(alpha = 0.12f),
                                labelColor = Color.White
                            )
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 4. Action Buttons: Rotate 90° & Reset
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = {
                            rotationDegrees = (rotationDegrees + 90) % 360
                            panOffset = Offset.Zero
                        },
                        shape = PillShape,
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White),
                        modifier = Modifier.defaultMinSize(minHeight = 48.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.RotateRight,
                            contentDescription = "Rotate 90 degrees",
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Rotate 90° ($rotationDegrees°)")
                    }

                    OutlinedButton(
                        onClick = {
                            zoomScale = 1f
                            panOffset = Offset.Zero
                            rotationDegrees = 0
                            selectedAspectRatio = CropAspectRatio.SQUARE
                        },
                        shape = PillShape,
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White.copy(alpha = 0.85f)),
                        modifier = Modifier.defaultMinSize(minHeight = 48.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.RestartAlt,
                            contentDescription = "Reset Adjustments",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Reset")
                    }
                }
            }
        }
    }
}

/**
 * Calculates and crops the bitmap according to the user's aspect ratio, zoom, and pan offset.
 * Ensures strict bounds safety and preserves the native image resolution and sharpness for QR scanning.
 */
private fun applyCrop(
    bitmap: Bitmap,
    aspectRatio: CropAspectRatio,
    zoom: Float,
    pan: Offset
): Bitmap {
    val imgW = bitmap.width
    val imgH = bitmap.height

    val targetRatio = when (aspectRatio) {
        CropAspectRatio.SQUARE -> 1f
        CropAspectRatio.FOUR_THREE -> 4f / 3f
        CropAspectRatio.THREE_FOUR -> 3f / 4f
        CropAspectRatio.SIXTEEN_NINE -> 16f / 9f
        CropAspectRatio.ORIGINAL -> imgW.toFloat() / imgH.toFloat()
    }

    val cropBounds = ImageEditUtils.calculateTargetDimensions(
        imgWidth = imgW,
        imgHeight = imgH,
        targetRatio = targetRatio,
        zoom = zoom,
        panX = pan.x,
        panY = pan.y
    )

    return ImageEditUtils.cropBitmap(bitmap, cropBounds.left, cropBounds.top, cropBounds.width, cropBounds.height)
}
