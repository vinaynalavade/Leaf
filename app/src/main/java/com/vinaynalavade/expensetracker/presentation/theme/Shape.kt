package com.vinaynalavade.expensetracker.presentation.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Shape scale for professional financial components.
 * Hierarchical continuous curvature provides a soft, luxury feel while maintaining clarity.
 */
val Shapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(24.dp),
    extraLarge = RoundedCornerShape(28.dp)
)

val HeroCardShape = RoundedCornerShape(28.dp)
val CardShape = RoundedCornerShape(24.dp)
val InnerCardShape = RoundedCornerShape(16.dp)
val ButtonShape = RoundedCornerShape(16.dp)
val InputShape = RoundedCornerShape(16.dp)
val ChipShape = RoundedCornerShape(10.dp)
val SquircleIconShape = RoundedCornerShape(14.dp)
val SheetShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
val DialogShape = RoundedCornerShape(28.dp)
val PillShape = RoundedCornerShape(percent = 50)

