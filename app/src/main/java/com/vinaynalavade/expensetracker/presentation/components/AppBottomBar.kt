package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.presentation.navigation.Screen

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow

val BottomNavItems = listOf(
    Screen.Dashboard,
    Screen.Transactions,
    Screen.Split,
    Screen.Analytics,
    Screen.Settings
)

/**
 * Premium, modern Bottom Navigation Bar for Leaf.
 * Features 20dp smooth rounded top geometry, luxury active indicator pills,
 * high-contrast typography, single-line text protection, and edge-to-edge inset handling.
 */
@Composable
fun AppBottomBar(
    currentRoute: String?,
    onNavigateToRoute: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
    val barShape = RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)

    NavigationBar(
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = 6.dp, shape = barShape)
            .clip(barShape)
            .drawBehind {
                drawLine(
                    color = borderColor,
                    start = Offset(0f, 0f),
                    end = Offset(size.width, 0f),
                    strokeWidth = 0.75.dp.toPx()
                )
            },
        containerColor = MaterialTheme.colorScheme.surface,
        contentColor = MaterialTheme.colorScheme.onSurface,
        tonalElevation = 2.dp,
        windowInsets = WindowInsets.navigationBars
    ) {

        BottomNavItems.forEach { screen ->
            val isSelected = currentRoute == screen.route ||
                (screen == Screen.Transactions && currentRoute?.startsWith("transactions") == true) ||
                (screen == Screen.Analytics && currentRoute == Screen.MonthlySummary.route) ||
                (screen == Screen.Split && currentRoute == Screen.Split.route)

            NavigationBarItem(
                selected = isSelected,
                onClick = {
                    if (!isSelected) {
                        val targetRoute = if (screen == Screen.Transactions) {
                            Screen.Transactions.createRoute()
                        } else {
                            screen.route
                        }
                        onNavigateToRoute(targetRoute)
                    }
                },
                alwaysShowLabel = true,
                icon = {
                    val icon = screen.icon
                    if (icon != null) {
                        Icon(
                            imageVector = icon,
                            contentDescription = stringResource(screen.titleResId),
                            modifier = Modifier.size(22.dp)
                        )
                    }
                },
                label = {
                    Text(
                        text = stringResource(screen.titleResId),
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                            letterSpacing = (-0.2).sp
                        ),
                        maxLines = 1,
                        softWrap = false,
                        overflow = TextOverflow.Ellipsis,
                        textAlign = TextAlign.Center
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.primary,
                    selectedTextColor = MaterialTheme.colorScheme.primary,
                    indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f),
                    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                )
            )
        }
    }
}
