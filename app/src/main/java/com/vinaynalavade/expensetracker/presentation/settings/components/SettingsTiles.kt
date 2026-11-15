package com.vinaynalavade.expensetracker.presentation.settings.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.presentation.theme.pressScale

/**
 * Standard palette for Apple-inspired Settings Category Squircles.
 * Vibrant, modern, and high-contrast while harmonious with Leaf's financial palette.
 */
object SettingsColors {
    val Blue = Color(0xFF007AFF)       // Language, Cloud Sync, Statements
    val Green = Color(0xFF34C759)      // Currency, Opening Balance, Savings, Ledgers
    val Orange = Color(0xFFFF9500)     // Categories, Budget Limit, Recents
    val Purple = Color(0xFFAF52DE)     // Recurring, Tools, Calculators
    val Red = Color(0xFFFF3B30)        // Master Notifications, Alerts
    val Indigo = Color(0xFF5856D6)     // Security, App Lock, Change PIN
    val Teal = Color(0xFF30B0C7)       // Reminders, Offsets, Schedule
    val Slate = Color(0xFF8E8E93)      // About, Info, Visibility
    val Mint = Color(0xFF00C7BE)       // Alternative Accent
}

/**
 * Grouped Section Container for Apple-inspired Settings in Leaf.
 * Provides an inset Level 1 card surface with uppercase category label and optional footnote.
 */
@Composable
fun SettingsSectionContainer(
    title: String,
    modifier: Modifier = Modifier,
    footer: String? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f),
            letterSpacing = 0.9.sp,
            modifier = Modifier.padding(start = 16.dp, top = 4.dp)
        )
        Surface(
            shape = RoundedCornerShape(18.dp),
            color = MaterialTheme.colorScheme.surface,
            border = BorderStroke(
                width = 0.8.dp,
                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
            ),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                content = content
            )
        }
        if (!footer.isNullOrBlank()) {
            Text(
                text = footer,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.75f),
                lineHeight = 16.sp,
                modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 2.dp)
            )
        }
    }
}

/**
 * Standardized icon box used across all Settings Tiles.
 * 32dp rounded squircle with vibrant background and high-contrast icon.
 */
@Composable
fun SettingsTileIconBox(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    tint: Color = Color.White,
    containerColor: Color = SettingsColors.Blue,
    iconSize: Dp = 18.dp,
    boxSize: Dp = 32.dp
) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = containerColor,
        modifier = modifier.size(boxSize)
    ) {
        Box(contentAlignment = Alignment.Center) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tint,
                modifier = Modifier.size(iconSize)
            )
        }
    }
}

/**
 * Standard Navigation Tile for Settings.
 * Provides a minimum 52dp effective touch target, full-row ripple, tactile press feedback,
 * right-aligned value, and forward chevron indicator.
 */
@Composable
fun SettingsNavigationTile(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    valueBadge: String? = null,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    iconTint: Color = Color.White,
    iconContainerColor: Color = SettingsColors.Blue,
    enabled: Boolean = true
) {
    val interactionSource = remember { MutableInteractionSource() }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 52.dp)
            .pressScale(interactionSource = interactionSource, enabled = enabled)
            .clickable(
                interactionSource = interactionSource,
                indication = androidx.compose.material3.ripple(),
                enabled = enabled,
                role = Role.Button,
                onClick = onClick
            )
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        SettingsTileIconBox(
            icon = icon,
            tint = iconTint,
            containerColor = iconContainerColor
        )

        Spacer(modifier = Modifier.width(14.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Normal,
                color = MaterialTheme.colorScheme.onSurface
            )
            if (!subtitle.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
                )
            }
        }

        if (valueBadge != null) {
            Text(
                text = valueBadge,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.75f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(start = 8.dp)
            )
        }

        Icon(
            imageVector = Icons.AutoMirrored.Filled.ArrowForwardIos,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.35f),
            modifier = Modifier
                .padding(start = 6.dp)
                .size(12.dp)
        )
    }
}

/**
 * Standard Switch / Toggle Tile for Settings.
 * Tapping anywhere on the row toggles the switch with subtle tactile feedback and haptics.
 */
@Composable
fun SettingsSwitchTile(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    iconTint: Color = Color.White,
    iconContainerColor: Color = SettingsColors.Green,
    enabled: Boolean = true
) {
    val haptic = LocalHapticFeedback.current
    val interactionSource = remember { MutableInteractionSource() }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 52.dp)
            .pressScale(interactionSource = interactionSource, enabled = enabled)
            .clickable(
                interactionSource = interactionSource,
                indication = androidx.compose.material3.ripple(),
                enabled = enabled,
                role = Role.Switch,
                onClick = {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onCheckedChange(!checked)
                }
            )
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        SettingsTileIconBox(
            icon = icon,
            tint = iconTint,
            containerColor = iconContainerColor
        )

        Spacer(modifier = Modifier.width(14.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Normal,
                color = MaterialTheme.colorScheme.onSurface
            )
            if (!subtitle.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
                )
            }
        }

        Spacer(modifier = Modifier.width(10.dp))

        Switch(
            checked = checked,
            onCheckedChange = { isChecked ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onCheckedChange(isChecked)
            },
            enabled = enabled,
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
                checkedTrackColor = MaterialTheme.colorScheme.primary,
                uncheckedThumbColor = MaterialTheme.colorScheme.outline,
                uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        )
    }
}

/**
 * Standard Value / Selection Tile for displaying current choice without navigating to a new screen.
 */
@Composable
fun SettingsValueTile(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    currentValue: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    iconTint: Color = Color.White,
    iconContainerColor: Color = SettingsColors.Blue
) {
    SettingsNavigationTile(
        icon = icon,
        title = title,
        subtitle = subtitle,
        valueBadge = currentValue,
        onClick = onClick,
        modifier = modifier,
        iconTint = iconTint,
        iconContainerColor = iconContainerColor
    )
}

/**
 * Standard Custom Row wrapper ensuring identical padding, alignment, and spacing grammar for embedded widgets.
 */
@Composable
fun SettingsCustomTile(
    title: String,
    subtitle: String? = null,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    iconTint: Color = Color.White,
    iconContainerColor: Color = SettingsColors.Blue,
    content: @Composable () -> Unit
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 52.dp)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            SettingsTileIconBox(
                icon = icon,
                tint = iconTint,
                containerColor = iconContainerColor
            )
            Spacer(modifier = Modifier.width(14.dp))
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Normal,
                color = MaterialTheme.colorScheme.onSurface
            )
            if (!subtitle.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.8f)
                )
            }
        }

        Spacer(modifier = Modifier.width(10.dp))

        content()
    }
}

/**
 * Inset divider between Settings Tiles in Apple-inspired grouped list.
 * Starts right where the label text begins (padded 62dp from start), keeping icons visually grouped.
 */
@Composable
fun SettingsDivider(
    modifier: Modifier = Modifier,
    startPadding: Dp = 62.dp
) {
    HorizontalDivider(
        modifier = modifier.padding(start = startPadding),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.28f),
        thickness = 0.6.dp
    )
}
