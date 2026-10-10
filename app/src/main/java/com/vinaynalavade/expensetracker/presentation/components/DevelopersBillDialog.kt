package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.core.easteregg.EasterEggEngine
import com.vinaynalavade.expensetracker.presentation.theme.BrandGreen
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.DialogShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing

/**
 * Fictional Easter Egg demonstration split: "The Bill That Started It All".
 * Non-persistent, read-only narrative showcasing how Leaf's Split 2.0 model was born.
 */
@Composable
fun DevelopersBillDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        shape = DialogShape,
        containerColor = MaterialTheme.colorScheme.surface,
        icon = {
            Surface(
                shape = CircleShape,
                color = BrandGreen.copy(alpha = 0.12f),
                modifier = Modifier.size(54.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.Restaurant,
                        contentDescription = null,
                        tint = BrandGreen,
                        modifier = Modifier.size(26.dp)
                    )
                }
            }
        },
        title = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = EasterEggEngine.MSG_DEVELOPERS_BILL_TITLE,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "A Late-Night Dhaba in Pune • The Origin of Split 2.0",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 380.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.md)
            ) {
                // Total Bill Banner
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = CardShape,
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Total Bill",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "5 Friends",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        Text(
                            text = "₹1,000.00",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = BrandGreen
                        )
                    }
                }

                // Story Narrative
                Text(
                    text = "The bill arrived. Someone suggested ₹1,000 ÷ 5 = ₹200 each. But Rohan had only a lime soda, while others ordered butter chicken.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 18.sp
                )

                // Breakdown Section
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "The Split 2.0 Solution:",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    BreakdownRow(
                        title = "Base Equal Share",
                        subtitle = "Shared starters & tax (₹500 ÷ 5)",
                        amount = "₹100 each"
                    )
                    BreakdownRow(
                        title = "Butter Chicken & Naan",
                        subtitle = "Vinay & Amit",
                        amount = "+₹150 each"
                    )
                    BreakdownRow(
                        title = "Paneer Tikka",
                        subtitle = "Sneha & Pooja",
                        amount = "+₹100 each"
                    )
                    BreakdownRow(
                        title = "Rohan's Drinks",
                        subtitle = "Covered under base share",
                        amount = "+₹0"
                    )
                }

                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f))

                // Final Settled Amounts
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = "Final Honest Shares:",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    ShareRow(name = "Vinay (You)", share = "₹250.00", desc = "₹100 base + ₹150 item")
                    ShareRow(name = "Amit", share = "₹250.00", desc = "₹100 base + ₹150 item")
                    ShareRow(name = "Sneha", share = "₹200.00", desc = "₹100 base + ₹100 item")
                    ShareRow(name = "Pooja", share = "₹200.00", desc = "₹100 base + ₹100 item")
                    ShareRow(name = "Rohan", share = "₹100.00", desc = "₹100 base only")
                }

                // Moral Quote Card
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = BrandGreen.copy(alpha = 0.08f),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, BrandGreen.copy(alpha = 0.25f), RoundedCornerShape(12.dp))
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.AutoAwesome,
                            contentDescription = null,
                            tint = BrandGreen,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "\"A shared expense should reflect responsibility, not assumptions. Every rupee should have a reason.\"",
                            style = MaterialTheme.typography.bodySmall,
                            fontStyle = FontStyle.Italic,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurface,
                            lineHeight = 16.sp
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                shape = ButtonShape,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Got It")
            }
        }
    )
}

@Composable
private fun BreakdownRow(title: String, subtitle: String, amount: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            text = amount,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun ShareRow(name: String, share: String, desc: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = name,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "($desc)",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Text(
            text = share,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Bold,
            color = BrandGreen
        )
    }
}
