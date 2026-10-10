package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import com.vinaynalavade.expensetracker.presentation.theme.Motion

val BottomNavItems = listOf(
    Screen.Dashboard,
    Screen.Transactions,
    Screen.Split,
    Screen.Planning,
    Screen.Insights
)

/**
 * Leaf Floating Navigation Dock.
 * Engineered for instant response, zero layout lag, and rock-solid geometric stability.
 * Features:
 * - Floating dock geometry with horizontal margins and system navigation clearance
 * - Translucent surface adapting strictly to Leaf Light and Obsidian theme tokens
 * - Per-tab geometric selection capsule with crisp 150ms alpha transition (no sliding blobs)
 * - Rock-solid layout: dock position, elevation, and icon/label alignments remain 100% stable
 * - Immediate visual feedback on touch, lightweight selection haptic, and full TalkBack semantics
 */
@Composable
fun AppBottomBar(
    currentRoute: String?,
    onNavigateToRoute: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f

    // Optimistic local selection state ensures 0ms visual latency on tap
    var optimisticRoute by remember(currentRoute) { mutableStateOf(currentRoute) }
    val activeRoute = optimisticRoute ?: currentRoute

    val selectedIndex = BottomNavItems.indexOfFirst { screen ->
        activeRoute == screen.route ||
            (screen == Screen.Transactions && activeRoute?.startsWith("transactions") == true) ||
            (screen == Screen.Insights && (activeRoute == Screen.Insights.route || activeRoute == Screen.MonthlySummary.route)) ||
            (screen == Screen.Planning && (activeRoute == Screen.Planning.route || activeRoute?.startsWith("goal_detail") == true)) ||
            (screen == Screen.Split && (activeRoute == Screen.Split.route || activeRoute?.startsWith("split") == true))
    }.let { if (it >= 0) it else 0 }

    val dockShape = RoundedCornerShape(26.dp)

    // Frosted glass translucent dock surfaces tailored for Leaf Light and Obsidian themes
    // High transparency allows background dashboard cards to subtly show through
    val dockContainerColor = if (isDark) {
        // Deep obsidian charcoal glass with subtle 72% translucency
        Color(0xB8121615)
    } else {
        // Pure crisp white glass with 70% translucency
        Color(0xB3FFFFFF)
    }

    val dockBorderColor = if (isDark) {
        // Subtle crisp light hairline rim that catches ambient light
        Color(0x28FFFFFF)
    } else {
        // Subtle neutral hairline rim for clean edge definition
        Color(0x18000000)
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(start = 18.dp, end = 18.dp, bottom = 8.dp, top = 2.dp),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(62.dp)
                .shadow(
                    elevation = if (isDark) 4.dp else 5.dp,
                    shape = dockShape,
                    ambientColor = if (isDark) Color(0x20000000) else Color(0x0A000000),
                    spotColor = if (isDark) Color(0x38000000) else Color(0x0E000000)
                )
                .border(
                    width = 0.5.dp,
                    color = dockBorderColor,
                    shape = dockShape
                ),
            shape = dockShape,
            color = dockContainerColor,
            tonalElevation = 0.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 6.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                BottomNavItems.forEachIndexed { index, screen ->
                    val isSelected = index == selectedIndex
                    val label = stringResource(screen.titleResId)

                    // Subtle tonal glass selection highlight built seamlessly into the dock
                    val capsuleBgColor by animateColorAsState(
                        targetValue = if (isSelected) {
                            if (isDark) {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.13f)
                            } else {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
                            }
                        } else {
                            Color.Transparent
                        },
                        animationSpec = tween(durationMillis = Motion.DurationFast, easing = Motion.EasingStandard),
                        label = "NavCapsuleBg"
                    )

                    val capsuleBorderColor by animateColorAsState(
                        targetValue = if (isSelected) {
                            if (isDark) {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.22f)
                            } else {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)
                            }
                        } else {
                            Color.Transparent
                        },
                        animationSpec = tween(durationMillis = Motion.DurationFast, easing = Motion.EasingStandard),
                        label = "NavCapsuleBorder"
                    )

                    val contentColor by animateColorAsState(
                        targetValue = if (isSelected) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (isDark) 0.55f else 0.65f)
                        },
                        animationSpec = tween(durationMillis = Motion.DurationFast, easing = Motion.EasingStandard),
                        label = "NavContentColor"
                    )

                    val tabShape = RoundedCornerShape(18.dp)

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .padding(horizontal = 2.dp, vertical = 2.dp)
                            .clip(tabShape)
                            .background(capsuleBgColor)
                            .border(
                                width = 0.5.dp,
                                color = capsuleBorderColor,
                                shape = tabShape
                            )
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null,
                                role = Role.Tab,
                                onClick = {
                                    if (!isSelected) {
                                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                        val targetRoute = if (screen == Screen.Transactions) {
                                            Screen.Transactions.createRoute()
                                        } else {
                                            screen.route
                                        }
                                        optimisticRoute = targetRoute
                                        onNavigateToRoute(targetRoute)
                                    }
                                }
                            )
                            .semantics {
                                this.selected = isSelected
                                this.role = Role.Tab
                                this.contentDescription = label
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier.fillMaxHeight()
                        ) {
                            val icon = screen.icon
                            if (icon != null) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = null,
                                    tint = contentColor,
                                    modifier = Modifier.size(19.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = label,
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 10.sp,
                                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                    letterSpacing = (-0.1).sp
                                ),
                                color = contentColor,
                                maxLines = 1,
                                softWrap = false,
                                overflow = TextOverflow.Ellipsis,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
    }
}
