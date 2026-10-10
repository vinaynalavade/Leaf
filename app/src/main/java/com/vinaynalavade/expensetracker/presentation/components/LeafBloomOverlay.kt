package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.core.easteregg.EasterEggEngine
import com.vinaynalavade.expensetracker.presentation.theme.BrandGreen
import com.vinaynalavade.expensetracker.presentation.theme.BrandGreenLight
import kotlinx.coroutines.delay
import kotlin.random.Random

private data class LeafParticle(
    var x: Float,
    var y: Float,
    val size: Float,
    val speedY: Float,
    val speedX: Float,
    var rotation: Float,
    val rotationSpeed: Float,
    val color: Color
)

/**
 * Purely cosmetic visual overlay: lightweight fluttering emerald leaves particle animation
 * triggered by the Konami-style finance sequence.
 * Auto-dismisses after 4 seconds. Zero persistent state or performance overhead.
 */
@Composable
fun LeafBloomOverlay(
    isVisible: Boolean,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    if (!isVisible) return

    var visible by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        delay(4200)
        visible = false
        delay(300)
        onDismiss()
    }

    val particleColors = listOf(
        BrandGreen,
        BrandGreenLight,
        Color(0xFF10B981),
        Color(0xFF34D399),
        Color(0xFF059669)
    )

    val particles = remember {
        List(24) {
            LeafParticle(
                x = Random.nextFloat(),
                y = -0.1f - Random.nextFloat() * 0.5f,
                size = 14f + Random.nextFloat() * 16f,
                speedY = 0.0018f + Random.nextFloat() * 0.0022f,
                speedX = (Random.nextFloat() - 0.5f) * 0.0012f,
                rotation = Random.nextFloat() * 360f,
                rotationSpeed = (Random.nextFloat() - 0.5f) * 4f,
                color = particleColors[it % particleColors.size]
            )
        }
    }

    var frameTick by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(Unit) {
        while (visible) {
            withFrameNanos {
                frameTick += 1f
                particles.forEach { p ->
                    p.y += p.speedY
                    p.x += p.speedX + (kotlin.math.sin((p.y * 10f).toDouble()).toFloat() * 0.0006f)
                    p.rotation += p.rotationSpeed
                }
            }
        }
    }

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = modifier.fillMaxSize()
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = {
                        visible = false
                        onDismiss()
                    }
                )
        ) {
            // Particle Canvas
            Canvas(modifier = Modifier.fillMaxSize()) {
                val w = size.width
                val h = size.height

                particles.forEach { p ->
                    val px = p.x * w
                    val py = p.y * h

                    if (py in -50f..(h + 50f)) {
                        rotate(degrees = p.rotation, pivot = Offset(px, py)) {
                            val leafPath = Path().apply {
                                moveTo(px, py - p.size)
                                cubicTo(
                                    px + p.size * 0.8f, py - p.size * 0.5f,
                                    px + p.size * 0.8f, py + p.size * 0.5f,
                                    px, py + p.size
                                )
                                cubicTo(
                                    px - p.size * 0.8f, py + p.size * 0.5f,
                                    px - p.size * 0.8f, py - p.size * 0.5f,
                                    px, py - p.size
                                )
                                close()
                            }
                            drawPath(
                                path = leafPath,
                                color = p.color.copy(alpha = 0.82f)
                            )
                        }
                    }
                }
            }

            // Top Banner Pill
            AnimatedVisibility(
                visible = visible,
                enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
                exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut(),
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(top = 16.dp)
            ) {
                Surface(
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                    shadowElevation = 8.dp,
                    modifier = Modifier.border(
                        width = 1.dp,
                        color = BrandGreen.copy(alpha = 0.4f),
                        shape = CircleShape
                    )
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 18.dp, vertical = 10.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = BrandGreen.copy(alpha = 0.15f),
                            modifier = Modifier.size(26.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Default.Eco,
                                    contentDescription = null,
                                    tint = BrandGreen,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = EasterEggEngine.MSG_KONAMI_UNLOCKED,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface,
                            letterSpacing = 0.2.sp
                        )
                    }
                }
            }
        }
    }
}
