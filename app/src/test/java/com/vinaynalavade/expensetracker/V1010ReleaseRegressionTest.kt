package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.calculator.FinancialCalculatorEngine
import com.vinaynalavade.expensetracker.presentation.components.BottomNavItems
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Release contract and regression test suite for Leaf v1.0.10.
 * Validates dashboard navigation routes, financial tools routes, calculator engines, and 5-tab BottomNav preservation.
 */
class V1010ReleaseRegressionTest {

    @Test
    fun testFivePrimaryNavigationTabsUnchanged() {
        assertEquals(5, BottomNavItems.size)
        assertEquals(Screen.Dashboard, BottomNavItems[0])
        assertEquals(Screen.Transactions, BottomNavItems[1])
        assertEquals(Screen.Split, BottomNavItems[2])
        assertEquals(Screen.Planning, BottomNavItems[3])
        assertEquals(Screen.Insights, BottomNavItems[4])

        BottomNavItems.forEach { screen ->
            assertNotNull("BottomNav item must have an icon: ${screen.route}", screen.icon)
            assertTrue("BottomNav item must have a valid title resource: ${screen.route}", screen.titleResId != 0)
        }
    }

    @Test
    fun testFinancialToolsAndCalculatorRoutesIntegrity() {
        assertEquals("tools", Screen.Tools.route)
        assertEquals("calculator_emi", Screen.EmiCalculator.route)
        assertEquals("calculator_sip", Screen.SipCalculator.route)
        assertEquals("calculator_fd", Screen.FdCalculator.route)
        assertEquals("calculator_rd", Screen.RdCalculator.route)
        assertEquals("calculator_discount", Screen.DiscountCalculator.route)
        assertEquals("calculator_gst", Screen.GstCalculator.route)
    }

    @Test
    fun testCoreScreensRouteIntegrity() {
        assertEquals("dashboard", Screen.Dashboard.route)
        assertEquals("settings", Screen.Settings.route)
        assertEquals("about", Screen.About.route)
    }

    @Test
    fun testFinancialCalculatorEnginesCalculations() {
        // EMI
        val emi = FinancialCalculatorEngine.calculateEmi(100_000.0, 10.0, 12)
        assertTrue(emi.monthlyEmi > 0)
        assertEquals(100_000.0, emi.totalPrincipal, 0.01)

        // SIP
        val sip = FinancialCalculatorEngine.calculateSip(5_000.0, 12.0, 5)
        assertEquals(300_000.0, sip.totalInvested, 0.01)
        assertTrue(sip.totalMaturity > sip.totalInvested)

        // FD
        val fd = FinancialCalculatorEngine.calculateFd(50_000.0, 7.5, 3.0)
        assertEquals(50_000.0, fd.investedAmount, 0.01)
        assertTrue(fd.maturityAmount > fd.investedAmount)

        // RD
        val rd = FinancialCalculatorEngine.calculateRd(2_000.0, 6.5, 24)
        assertEquals(48_000.0, rd.investedAmount, 0.01)
        assertTrue(rd.maturityAmount > rd.investedAmount)

        // Discount
        val discount = FinancialCalculatorEngine.calculateDiscount(1_000.0, 15.0)
        assertEquals(150.0, discount.discountAmount, 0.01)
        assertEquals(850.0, discount.finalPrice, 0.01)

        // GST
        val gstExclusive = FinancialCalculatorEngine.calculateGst(1_000.0, 18.0, isInclusive = false)
        assertEquals(180.0, gstExclusive.gstAmount, 0.01)
        assertEquals(1_180.0, gstExclusive.totalAmount, 0.01)

        val gstInclusive = FinancialCalculatorEngine.calculateGst(1_180.0, 18.0, isInclusive = true)
        assertEquals(1_000.0, gstInclusive.netAmount, 0.01)
        assertEquals(180.0, gstInclusive.gstAmount, 0.01)
    }
}
