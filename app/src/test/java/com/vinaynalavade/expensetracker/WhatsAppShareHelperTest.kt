package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.share.WhatsAppShareHelper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WhatsAppShareHelperTest {

    @Test
    fun createPersonalizedMessage_pendingParticipant_containsAllRequiredContext() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val yourShare = Amount.fromSubunits(32500L) // ₹325.00
        val message = WhatsAppShareHelper.createPersonalizedMessage(
            expenseTitle = "Dinner at ABC",
            participantName = "Rahul",
            totalBill = totalBill,
            userShare = yourShare,
            paidAmount = Amount.ZERO,
            remainingAmount = yourShare,
            hasQrCode = true,
            currency = Currency.INR
        )

        // 1. Participant name
        assertTrue("Must address participant", message.contains("Rahul"))
        // 2. Bill title
        assertTrue("Must include bill title", message.contains("Dinner at ABC"))
        // 3. Out of how much context (total bill)
        assertTrue("Must include total bill", message.contains("Total bill: ₹1,000.00"))
        // 4. Their share
        assertTrue("Must include user share", message.contains("Your share: ₹325.00"))
        // 5. Paid amount
        assertTrue("Must include paid amount", message.contains("Paid: ₹0.00"))
        // 6. Remaining amount
        assertTrue("Must include remaining amount", message.contains("Remaining: ₹325.00"))
        // 7. Settlement request
        assertTrue("Must request settlement", message.contains("Please settle ₹325.00."))
        // 8. Attached UPI QR reference
        assertTrue("Must mention QR", message.contains("attached QR code"))
    }

    @Test
    fun createPersonalizedMessage_settledParticipant_formatsSettledState() {
        val totalBill = Amount.fromSubunits(100000L)
        val yourShare = Amount.fromSubunits(25000L)
        val message = WhatsAppShareHelper.createPersonalizedMessage(
            expenseTitle = "Goa Trip",
            participantName = "Priya",
            totalBill = totalBill,
            userShare = yourShare,
            paidAmount = yourShare,
            remainingAmount = Amount.ZERO,
            hasQrCode = false,
            currency = Currency.INR
        )

        assertTrue(message.contains("Priya"))
        assertTrue(message.contains("Total bill: ₹1,000.00"))
        assertTrue(message.contains("Your share: ₹250.00"))
        assertTrue(message.contains("Paid: ₹250.00"))
        assertTrue(message.contains("Remaining: ₹0.00"))
        assertTrue(message.contains("fully settled"))
    }

    @Test
    fun createConsolidatedMessage_formatsGroupReminder() {
        val totalBill = Amount.fromSubunits(100000L)
        val shareEach = Amount.fromSubunits(20000L)
        val message = WhatsAppShareHelper.createConsolidatedMessage(
            expenseTitle = "Dinner",
            totalBill = totalBill,
            shareEach = shareEach,
            hasQrCode = true,
            currency = Currency.INR
        )

        assertTrue(message.contains("Hey everyone"))
        assertTrue(message.contains("Dinner"))
        assertTrue(message.contains("Total bill: ₹1,000.00"))
        assertTrue(message.contains("Share each: ₹200.00"))
        assertTrue(message.contains("Please settle ₹200.00"))
        assertTrue(message.contains("QR code"))
    }

    @Test
    fun normalizePhoneNumber_cleansVariousFormatsCorrectly() {
        // Standard 10 digit Indian number without country code
        assertEquals("919876543210", WhatsAppShareHelper.normalizePhoneNumber("9876543210"))

        // With +91 country code and formatting characters
        assertEquals("919876543210", WhatsAppShareHelper.normalizePhoneNumber("+91 98765-43210"))

        // International format
        assertEquals("14155552671", WhatsAppShareHelper.normalizePhoneNumber("+1 (415) 555-2671"))

        // Null / blank
        assertEquals("", WhatsAppShareHelper.normalizePhoneNumber(null))
        assertEquals("", WhatsAppShareHelper.normalizePhoneNumber("   "))
    }
}
