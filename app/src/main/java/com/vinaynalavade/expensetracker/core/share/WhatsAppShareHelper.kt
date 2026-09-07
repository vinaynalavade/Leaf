package com.vinaynalavade.expensetracker.core.share

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency

/**
 * Helper utility for generating and launching personalized WhatsApp payment reminders.
 */
object WhatsAppShareHelper {

    private const val WHATSAPP_PACKAGE = "com.whatsapp"

    /**
     * Builds the personalized payment reminder message.
     *
     * @param expenseTitle Title of the shared expense (e.g., "Dinner").
     * @param participantName Name of the person when sharing individually, or null for group.
     * @param amount The individual share amount owed.
     * @param currency The user's active currency.
     * @param isConsolidated True if this is a single consolidated message for all participants.
     */
    fun createShareMessage(
        expenseTitle: String,
        participantName: String?,
        amount: Amount,
        currency: Currency = Currency.DEFAULT,
        isConsolidated: Boolean = false
    ): String {
        val formattedAmount = amount.format(currency)
        return if (isConsolidated || participantName.isNullOrBlank()) {
            "Hey everyone 👋\nYour share for $expenseTitle is $formattedAmount each.\nPlease pay $formattedAmount using the UPI QR below.\nThanks!"
        } else {
            "Hey $participantName 👋\nYour share for $expenseTitle is $formattedAmount.\nPlease pay $formattedAmount using the UPI QR below.\nThanks!"
        }
    }

    /**
     * Shares the payment message and optional QR image directly to WhatsApp,
     * falling back to the Android system share sheet if WhatsApp is not installed.
     */
    fun sharePaymentReminder(
        context: Context,
        message: String,
        qrImageUri: Uri? = null,
        title: String = "Share Payment Reminder"
    ) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            if (qrImageUri != null) {
                type = "image/*"
                putExtra(Intent.EXTRA_STREAM, qrImageUri)
                putExtra(Intent.EXTRA_TEXT, message)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, message)
            }
        }

        // Try direct WhatsApp intent first
        val whatsappIntent = Intent(shareIntent).setPackage(WHATSAPP_PACKAGE)
        val chooserIntent = Intent.createChooser(shareIntent, title).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            whatsappIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(whatsappIntent)
        } catch (_: ActivityNotFoundException) {
            // Fallback to system share chooser
            try {
                context.startActivity(chooserIntent)
            } catch (_: Exception) {
                // Context cannot open chooser
            }
        } catch (_: Exception) {
            try {
                context.startActivity(chooserIntent)
            } catch (_: Exception) {
                // Ignore failure
            }
        }
    }
}
