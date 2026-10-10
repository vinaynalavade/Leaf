package com.vinaynalavade.expensetracker.core.share

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency

/**
 * Helper utility for generating and launching dynamic personalized WhatsApp payment reminders.
 */
object WhatsAppShareHelper {

    private const val WHATSAPP_PACKAGE = "com.whatsapp"
    private const val WHATSAPP_BUSINESS_PACKAGE = "com.whatsapp.w4b"

    /**
     * Normalizes a phone number for WhatsApp deep-linking.
     * Strips non-digit formatting characters and ensures international format.
     */
    fun normalizePhoneNumber(phone: String?): String {
        if (phone.isNullOrBlank()) return ""
        val trimmed = phone.trim()
        val digits = trimmed.filter { it.isDigit() }
        if (digits.isBlank()) return ""

        // If explicitly started with +, preserve full international digits
        if (trimmed.startsWith("+")) {
            return digits
        }

        // If exactly 10 digits (standard Indian mobile format in Leaf), default to 91 country code
        return if (digits.length == 10) {
            "91$digits"
        } else {
            digits
        }
    }

    /**
     * Builds a rich, dynamic personalized payment reminder message for an individual participant.
     *
     * Clearly communicates "Out of how much" so the recipient understands their share in context.
     *
     * @param expenseTitle Title of the shared bill.
     * @param participantName Name of the participant.
     * @param totalBill Total expense bill amount.
     * @param userShare The participant's calculated portion.
     * @param paidAmount Amount already paid/settled by this participant.
     * @param remainingAmount Remaining amount owed by this participant.
     * @param hasQrCode Whether a UPI payment QR is attached.
     * @param currency User currency.
     */
    fun createPersonalizedMessage(
        expenseTitle: String,
        participantName: String,
        totalBill: Amount,
        userShare: Amount,
        paidAmount: Amount = Amount.ZERO,
        remainingAmount: Amount = userShare,
        hasQrCode: Boolean = false,
        currency: Currency = Currency.DEFAULT
    ): String {
        val formattedTotal = totalBill.format(currency)
        val formattedShare = userShare.format(currency)
        val formattedPaid = paidAmount.format(currency)
        val formattedRemaining = remainingAmount.format(currency)

        val qrNote = if (hasQrCode) "\n\nYou can scan the attached QR code to pay via UPI." else ""

        val actionLine = if (remainingAmount.subunits > 0L) {
            "Please settle $formattedRemaining."
        } else {
            "Your share is fully settled. Thank you!"
        }

        return "Hi $participantName 👋\n\n" +
            "For \"$expenseTitle\":\n\n" +
            "Total bill: $formattedTotal\n" +
            "Your share: $formattedShare\n" +
            "Paid: $formattedPaid\n" +
            "Remaining: $formattedRemaining\n\n" +
            actionLine +
            qrNote +
            "\n\nThanks!"
    }

    /**
     * Builds a consolidated payment reminder message for group sharing.
     */
    fun createConsolidatedMessage(
        expenseTitle: String,
        totalBill: Amount,
        shareEach: Amount,
        hasQrCode: Boolean = false,
        currency: Currency = Currency.DEFAULT
    ): String {
        val formattedTotal = totalBill.format(currency)
        val formattedEach = shareEach.format(currency)
        val qrNote = if (hasQrCode) "\n\nYou can scan the attached QR code to pay via UPI." else ""

        return "Hey everyone 👋\n\n" +
            "For \"$expenseTitle\":\n\n" +
            "Total bill: $formattedTotal\n" +
            "Share each: $formattedEach\n\n" +
            "Please settle $formattedEach." +
            qrNote +
            "\n\nThanks!"
    }

    /**
     * Backward-compatible helper for simple reminders.
     */
    fun createShareMessage(
        expenseTitle: String,
        participantName: String?,
        amount: Amount,
        currency: Currency = Currency.DEFAULT,
        isConsolidated: Boolean = false
    ): String {
        return if (isConsolidated || participantName.isNullOrBlank()) {
            createConsolidatedMessage(
                expenseTitle = expenseTitle,
                totalBill = amount,
                shareEach = amount,
                hasQrCode = false,
                currency = currency
            )
        } else {
            createPersonalizedMessage(
                expenseTitle = expenseTitle,
                participantName = participantName,
                totalBill = amount,
                userShare = amount,
                paidAmount = Amount.ZERO,
                remainingAmount = amount,
                hasQrCode = false,
                currency = currency
            )
        }
    }

    /**
     * Shares payment reminder directly to a specific participant's WhatsApp if their phone number
     * is available, falling back gracefully to general WhatsApp share or system share sheet.
     *
     * @param context Android context.
     * @param message Text message content.
     * @param qrImageUri Optional FileProvider Uri for UPI QR image.
     * @param phoneNumber Optional contact phone number for direct chat targeting.
     * @param title Title for fallback chooser.
     */
    fun sharePaymentReminder(
        context: Context,
        message: String,
        qrImageUri: Uri? = null,
        phoneNumber: String? = null,
        title: String = "Share Payment Reminder"
    ) {
        val cleanNumber = normalizePhoneNumber(phoneNumber)

        // Case 1: Direct targeting to WhatsApp contact phone number
        if (cleanNumber.isNotBlank()) {
            if (qrImageUri != null) {
                // Image + Text directly targeted with jid
                val directSendIntent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/*"
                    putExtra(Intent.EXTRA_STREAM, qrImageUri)
                    putExtra(Intent.EXTRA_TEXT, message)
                    putExtra("jid", "$cleanNumber@s.whatsapp.net")
                    setPackage(WHATSAPP_PACKAGE)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }

                try {
                    context.startActivity(directSendIntent)
                    return
                } catch (_: Exception) {
                    // Try WhatsApp Business package
                    try {
                        directSendIntent.setPackage(WHATSAPP_BUSINESS_PACKAGE)
                        context.startActivity(directSendIntent)
                        return
                    } catch (_: Exception) {
                        // Fall back to direct WhatsApp URL or general chooser
                    }
                }
            }

            // Direct WhatsApp chat URL targeting that specific number
            val waUri = Uri.parse("https://api.whatsapp.com/send?phone=$cleanNumber&text=${Uri.encode(message)}")
            val directViewIntent = Intent(Intent.ACTION_VIEW, waUri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            try {
                directViewIntent.setPackage(WHATSAPP_PACKAGE)
                context.startActivity(directViewIntent)
                return
            } catch (_: ActivityNotFoundException) {
                try {
                    directViewIntent.setPackage(WHATSAPP_BUSINESS_PACKAGE)
                    context.startActivity(directViewIntent)
                    return
                } catch (_: Exception) {
                    // Try without setting package (browser / general handler)
                    try {
                        directViewIntent.setPackage(null)
                        context.startActivity(directViewIntent)
                        return
                    } catch (_: Exception) {
                        // Fall through to general chooser
                    }
                }
            } catch (_: Exception) {
                // Fall through to general chooser
            }
        }

        // Case 2: General Share fallback (WhatsApp or System Chooser)
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

        val whatsappIntent = Intent(shareIntent).setPackage(WHATSAPP_PACKAGE).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val chooserIntent = Intent.createChooser(shareIntent, title).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            context.startActivity(whatsappIntent)
        } catch (_: ActivityNotFoundException) {
            try {
                whatsappIntent.setPackage(WHATSAPP_BUSINESS_PACKAGE)
                context.startActivity(whatsappIntent)
            } catch (_: ActivityNotFoundException) {
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
        } catch (_: Exception) {
            try {
                context.startActivity(chooserIntent)
            } catch (_: Exception) {
                // Ignore failure
            }
        }
    }
}
