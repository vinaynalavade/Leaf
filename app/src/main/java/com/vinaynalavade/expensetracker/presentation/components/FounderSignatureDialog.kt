package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
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
import com.vinaynalavade.expensetracker.presentation.theme.DialogShape

/**
 * Easter Egg #10: Founder Signature
 * "Built with too many cups of chai. — Vinay"
 */
@Composable
fun FounderSignatureDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        shape = DialogShape,
        containerColor = MaterialTheme.colorScheme.surface,
        title = null,
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp, horizontal = 4.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "☕",
                    fontSize = 36.sp
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = EasterEggEngine.MSG_FOUNDER_SIGNATURE,
                    style = MaterialTheme.typography.titleSmall.copy(
                        fontWeight = FontWeight.SemiBold,
                        fontStyle = FontStyle.Italic
                    ),
                    color = BrandGreen,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Crafted with care for calm, private, offline-first personal finance.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                shape = ButtonShape,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Cheers ☕")
            }
        }
    )
}
