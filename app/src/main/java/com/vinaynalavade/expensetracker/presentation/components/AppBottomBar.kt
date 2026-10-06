package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
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

val BottomNavItems = listOf(
    Screen.Dashboard,
    Screen.Transactions,
    Screen.Split,
    Screen.Planning,
    Screen.Insights
)

/**
 * Leaf Floating Premium Navigation Dock.
 * Inspired by modern iPhone/iPad floating surfaces and premium fintech navigation.
 * Features:
 * - Floating capsule geometry with horizontal margins and system navigation clearance
 * - Translucent surface with delicate border and ambient depth
 * - Physically animated sliding selection pill indicator using tactile spring physics
 * - Subtle icon scale and high-contrast bold active typography
 * - Tactile haptic feedback and TalkBack accessibility
 */
@Composable
fun AppBottomBar(
    currentRoute: String?,
    onNavigateToRoute: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val isDark = isSystemInDarkTheme() || MaterialTheme.colorScheme.surface.luminance() < 0.5f

    val selectedIndex = BottomNavItems.indexOfFirst { screen ->
        currentRoute == screen.route ||
            (screen == Screen.Transactions && currentRoute?.startsWith("transactions") == true) ||
            (screen == Screen.Insights && (currentRoute == Screen.Insights.route || currentRoute == Screen.MonthlySummary.route)) ||
            (screen == Screen.Planning && (currentRoute == Screen.Planning.route || currentRoute?.startsWith("goal_detail") == true)) ||
            (screen == Screen.Split && (currentRoute == Screen.Split.route || currentRoute?.startsWith("split") == true))
    }.let { if (it >= 0) it else 0 }

    val dockShape = RoundedCornerShape(32.dp)

    // Luminous translucent surfaces tailored for Leaf Light and Obsidian themes
    val dockContainerColor = if (isDark) {
        Color(0xFF141716).copy(alpha = 0.92f)
    } else {
        Color(0xFFFCFCFD).copy(alpha = 0.94f)
    }

    val dockBorderColor = if (isDark) {
        Color(0xFF2E3532).copy(alpha = 0.70f)
    } else {
        Color(0xFFE2E8F0).copy(alpha = 0.85f)
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(start = 20.dp, end = 20.dp, bottom = 10.dp, top = 6.dp),
        contentAlignment = Alignment.Center
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .height(66.dp)
                .shadow(
                    elevation = if (isDark) 8.dp else 10.dp,
                    shape = dockShape,
                    ambientColor = if (isDark) Color(0x30000000) else Color(0x0E000000),
                    spotColor = if (isDark) Color(0x60000000) else Color(0x1A000000)
                )
                .border(
                    width = 0.8.dp,
                    color = dockBorderColor,
                    shape = dockShape
                ),
            shape = dockShape,
            color = dockContainerColor,
            tonalElevation = 0.dp
        ) {
            BoxWithConstraints(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 6.dp, vertical = 6.dp)
            ) {
                val tabWidth = maxWidth / BottomNavItems.size

                // Smooth sliding animated pill indicator traveling between destinations
                val indicatorOffset by animateDpAsState(
                    targetValue = tabWidth * selectedIndex,
                    animationSpec = spring(
                        dampingRatio = 0.78f,
                        stiffness = Spring.StiffnessMediumLow
                    ),
                    label = "FloatingDockIndicatorOffset"
                )

                // Elevated active selection surface
                Box(
                    modifier = Modifier
                        .offset(x = indicatorOffset)
                        .width(tabWidth)
                        .fillMaxHeight()
                        .padding(horizontal = 3.dp, vertical = 2.dp)
                        .clip(RoundedCornerShape(26.dp))
                        .background(
                            if (isDark) {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.16f)
                            } else {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                            }
                        )
                        .border(
                            width = 1.dp,
                            color = if (isDark) {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.22f)
                            } else {
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)
                            },
                            shape = RoundedCornerShape(26.dp)
                        )
                )

                // Five destination tabs
                Row(
                    modifier = Modifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    BottomNavItems.forEachIndexed { index, screen ->
                        val isSelected = index == selectedIndex
                        val label = stringResource(screen.titleResId)

                        // Controlled micro-scale bounce for active icon
                        val iconScale by animateFloatAsState(
                            targetValue = if (isSelected) 1.08f else 1.0f,
                            animationSpec = spring(
                                dampingRatio = 0.75f,
                                stiffness = Spring.StiffnessMediumLow
                            ),
                            label = "NavIconScale"
                        )

                        val activeContentColor = MaterialTheme.colorScheme.primary
                        val inactiveContentColor = if (isDark) {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.65f)
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.72f)
                        }
                        val contentColor = if (isSelected) activeContentColor else inactiveContentColor

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(26.dp))
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = null,
                                    role = Role.Tab,
                                    onClick = {
                                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                        if (!isSelected) {
                                            val targetRoute = if (screen == Screen.Transactions) {
                                                Screen.Transactions.createRoute()
                                            } else {
                                                screen.route
                                            }
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
                                        modifier = Modifier
                                            .size(21.dp)
                                            .scale(iconScale)
                                    )
                                }
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontSize = 10.5.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                        letterSpacing = (-0.2).sp
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
}
