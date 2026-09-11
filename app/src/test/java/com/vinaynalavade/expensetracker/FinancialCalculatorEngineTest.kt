package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.calculator.FinancialCalculatorEngine
import org.junit.Assert.assertEquals
import org.junit.Test

class FinancialCalculatorEngineTest {

    @Test
    fun `test EMI calculation standard loan`() {
        // Principal = 1,00,000, Rate = 12% p.a., Tenure = 12 months
        // Monthly rate r = 1% = 0.01
        // EMI = 100000 * 0.01 * (1.01^12) / (1.01^12 - 1) = ~8884.88
        val result = FinancialCalculatorEngine.calculateEmi(100_000.0, 12.0, 12)
        assertEquals(8884.88, result.monthlyEmi, 0.5)
        assertEquals(100_000.0, result.totalPrincipal, 0.01)
        assertEquals(6618.55, result.totalInterest, 0.5)
        assertEquals(106618.55, result.totalPayment, 0.5)
    }

    @Test
    fun `test EMI calculation zero interest`() {
        val result = FinancialCalculatorEngine.calculateEmi(120_000.0, 0.0, 12)
        assertEquals(10_000.0, result.monthlyEmi, 0.01)
        assertEquals(0.0, result.totalInterest, 0.01)
        assertEquals(120_000.0, result.totalPayment, 0.01)
    }

    @Test
    fun `test SIP calculation beginning of month annuity due`() {
        // Monthly = 5,000, Return = 12% p.a., Tenure = 10 years (120 months)
        // i = 0.01
        // Maturity = 5000 * ((1.01^120 - 1)/0.01) * 1.01 = 5000 * 230.038689 * 1.01 = ~11,61,695.38
        val result = FinancialCalculatorEngine.calculateSip(5000.0, 12.0, 10)
        assertEquals(600_000.0, result.totalInvested, 0.01)
        assertEquals(1161695.38, result.totalMaturity, 1.0)
        assertEquals(561695.38, result.estimatedReturns, 1.0)
    }

    @Test
    fun `test SIP calculation zero return`() {
        val result = FinancialCalculatorEngine.calculateSip(1000.0, 0.0, 5)
        assertEquals(60_000.0, result.totalInvested, 0.01)
        assertEquals(0.0, result.estimatedReturns, 0.01)
        assertEquals(60_000.0, result.totalMaturity, 0.01)
    }

    @Test
    fun `test FD calculation quarterly compounding`() {
        // Principal = 100,000, Rate = 8% p.a., Tenure = 5 years (20 quarters)
        // A = 100000 * (1 + 0.08/4)^20 = 100000 * 1.02^20 = 148594.74
        val result = FinancialCalculatorEngine.calculateFd(100_000.0, 8.0, 5.0)
        assertEquals(100_000.0, result.investedAmount, 0.01)
        assertEquals(148594.74, result.maturityAmount, 0.5)
        assertEquals(48594.74, result.totalInterest, 0.5)
    }

    @Test
    fun `test RD calculation quarterly compounding`() {
        // Monthly = 1,000, Rate = 6% p.a., Tenure = 12 months
        val result = FinancialCalculatorEngine.calculateRd(1000.0, 6.0, 12)
        assertEquals(12000.0, result.investedAmount, 0.01)
        // Exact IBA quarterly compounding sum for 1000 @ 6% for 12 months is ~12,395.20
        assertEquals(12395.20, result.maturityAmount, 0.5)
        assertEquals(395.20, result.totalInterest, 0.5)
    }

    @Test
    fun `test Discount calculation`() {
        val result = FinancialCalculatorEngine.calculateDiscount(2500.0, 20.0)
        assertEquals(2500.0, result.originalPrice, 0.01)
        assertEquals(20.0, result.discountPercent, 0.01)
        assertEquals(500.0, result.discountAmount, 0.01)
        assertEquals(2000.0, result.finalPrice, 0.01)
    }

    @Test
    fun `test GST exclusive and inclusive calculation`() {
        // Exclusive: 1000 + 18% GST = 1180 total, CGST = 90, SGST = 90
        val exclusiveResult = FinancialCalculatorEngine.calculateGst(1000.0, 18.0, isInclusive = false)
        assertEquals(1000.0, exclusiveResult.netAmount, 0.01)
        assertEquals(180.0, exclusiveResult.gstAmount, 0.01)
        assertEquals(90.0, exclusiveResult.cgstAmount, 0.01)
        assertEquals(90.0, exclusiveResult.sgstAmount, 0.01)
        assertEquals(1180.0, exclusiveResult.totalAmount, 0.01)

        // Inclusive: 1180 total @ 18% -> Net = 1000, GST = 180
        val inclusiveResult = FinancialCalculatorEngine.calculateGst(1180.0, 18.0, isInclusive = true)
        assertEquals(1000.0, inclusiveResult.netAmount, 0.01)
        assertEquals(180.0, inclusiveResult.gstAmount, 0.01)
        assertEquals(90.0, inclusiveResult.cgstAmount, 0.01)
        assertEquals(90.0, inclusiveResult.sgstAmount, 0.01)
        assertEquals(1180.0, inclusiveResult.totalAmount, 0.01)
    }
}
