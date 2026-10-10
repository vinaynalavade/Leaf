package com.vinaynalavade.expensetracker.presentation.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.easteregg.EasterEggEngine
import com.vinaynalavade.expensetracker.presentation.theme.BrandGreen
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.DialogShape

/**
 * Easter Egg #1: The Hidden Leaf
 * Displayed after tapping the official Leaf logo 7 times.
 */
@Composable
fun HiddenLeafDialog(
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
                modifier = Modifier.size(56.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Image(
                        painter = painterResource(id = R.drawable.ic_leaf_logo),
                        contentDescription = stringResource(R.string.app_name),
                        modifier = Modifier.size(36.dp),
                        contentScale = ContentScale.Fit
                    )
                }
            }
        },
        title = {
            Text(
                text = "The Hidden Leaf",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        },
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = EasterEggEngine.MSG_HIDDEN_LEAF,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontWeight = FontWeight.Medium,
                        fontStyle = FontStyle.Italic
                    ),
                    color = BrandGreen,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Thank you for being curious and exploring every detail of Leaf.",
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
                Text("Close")
            }
        }
    )
}
