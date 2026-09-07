package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.share.WhatsAppShareHelper
import org.junit.Assert.assertTrue
import org.junit.Test

class WhatsAppShareHelperTest {

    @Test
    fun createShareMessage_consolidated_formatsGroupReminder() {
        val amount = Amount.fromSubunits(100000L) // ₹1,000.00
        val message = WhatsAppShareHelper.createShareMessage(
            expenseTitle = "Dinner",
            participantName = null,
            amount = amount,
            currency = Currency.INR,
            isConsolidated = true
        )

        assertTrue(message.contains("Hey everyone"))
        assertTrue(message.contains("Dinner"))
        assertTrue(message.contains("₹1,000.00"))
        assertTrue(message.contains("each"))
        assertTrue(message.contains("UPI QR"))
    }

    @Test
    fun createShareMessage_individual_formatsPersonalizedReminder() {
        val amount = Amount.fromSubunits(80000L) // ₹800.00
        val message = WhatsAppShareHelper.createShareMessage(
            expenseTitle = "Dinner",
            participantName = "Rahul",
            amount = amount,
            currency = Currency.INR,
            isConsolidated = false
        )

        assertTrue(message.contains("Hey Rahul"))
        assertTrue(message.contains("Dinner"))
        assertTrue(message.contains("₹800.00"))
        assertTrue(message.contains("UPI QR"))
    }
}
