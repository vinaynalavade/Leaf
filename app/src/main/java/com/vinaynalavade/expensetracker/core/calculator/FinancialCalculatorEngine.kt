package com.vinaynalavade.expensetracker.core.calculator

import kotlin.math.pow

data class EmiResult(
    val monthlyEmi: Double,
    val totalPrincipal: Double,
    val totalInterest: Double,
    val totalPayment: Double
)

data class SipResult(
    val totalInvested: Double,
    val estimatedReturns: Double,
    val totalMaturity: Double
)

data class FdResult(
    val investedAmount: Double,
    val totalInterest: Double,
    val maturityAmount: Double
)

data class RdResult(
    val investedAmount: Double,
    val totalInterest: Double,
    val maturityAmount: Double
)

data class DiscountResult(
    val originalPrice: Double,
    val discountPercent: Double,
    val discountAmount: Double,
    val finalPrice: Double
)

data class GstResult(
    val netAmount: Double,
    val gstAmount: Double,
    val cgstAmount: Double,
    val sgstAmount: Double,
    val totalAmount: Double,
    val isInclusive: Boolean
)

object FinancialCalculatorEngine {

    /**
     * Calculate Equated Monthly Installment (EMI)
     * @param principal Principal loan amount
     * @param annualRatePercent Annual interest rate (e.g. 8.5 for 8.5%)
     * @param tenureMonths Loan tenure in total months
     */
    fun calculateEmi(principal: Double, annualRatePercent: Double, tenureMonths: Int): EmiResult {
        if (principal <= 0 || tenureMonths <= 0) {
            return EmiResult(0.0, principal.coerceAtLeast(0.0), 0.0, principal.coerceAtLeast(0.0))
        }
        if (annualRatePercent <= 0) {
            val emi = principal / tenureMonths
            return EmiResult(emi, principal, 0.0, principal)
        }

        val monthlyRate = annualRatePercent / (12.0 * 100.0)
        val factor = (1.0 + monthlyRate).pow(tenureMonths.toDouble())
        val emi = principal * monthlyRate * factor / (factor - 1.0)
        val totalPayment = emi * tenureMonths
        val totalInterest = totalPayment - principal

        return EmiResult(
            monthlyEmi = emi,
            totalPrincipal = principal,
            totalInterest = totalInterest.coerceAtLeast(0.0),
            totalPayment = totalPayment
        )
    }

    /**
     * Calculate Systematic Investment Plan (SIP)
     * Beginning-of-month annuity due formula: M * [((1+i)^n - 1) / i] * (1+i)
     * @param monthlyInvestment Monthly investment amount (M)
     * @param annualExpectedReturnPercent Expected annual return rate in % [0, 50]
     * @param tenureYears Investment duration in years
     */
    fun calculateSip(monthlyInvestment: Double, annualExpectedReturnPercent: Double, tenureYears: Int): SipResult {
        if (monthlyInvestment <= 0 || tenureYears <= 0) {
            return SipResult(0.0, 0.0, 0.0)
        }
        val clampedRate = annualExpectedReturnPercent.coerceIn(0.0, 50.0)
        val totalMonths = tenureYears * 12
        val totalInvested = monthlyInvestment * totalMonths

        if (clampedRate == 0.0) {
            return SipResult(
                totalInvested = totalInvested,
                estimatedReturns = 0.0,
                totalMaturity = totalInvested
            )
        }

        val monthlyRate = clampedRate / (12.0 * 100.0)
        val factor = (1.0 + monthlyRate).pow(totalMonths.toDouble())
        val maturity = monthlyInvestment * ((factor - 1.0) / monthlyRate) * (1.0 + monthlyRate)
        val estimatedReturns = (maturity - totalInvested).coerceAtLeast(0.0)

        return SipResult(
            totalInvested = totalInvested,
            estimatedReturns = estimatedReturns,
            totalMaturity = maturity
        )
    }

    /**
     * Calculate Fixed Deposit (FD) with quarterly compounding: A = P * (1 + r/4)^(4*t)
     * @param principal Deposit amount
     * @param annualRatePercent Annual interest rate %
     * @param tenureYears Duration in years
     */
    fun calculateFd(principal: Double, annualRatePercent: Double, tenureYears: Double): FdResult {
        if (principal <= 0 || tenureYears <= 0) {
            return FdResult(principal.coerceAtLeast(0.0), 0.0, principal.coerceAtLeast(0.0))
        }
        if (annualRatePercent <= 0) {
            return FdResult(principal, 0.0, principal)
        }

        val rate = annualRatePercent / 100.0
        val quarters = 4.0 * tenureYears
        val maturity = principal * (1.0 + rate / 4.0).pow(quarters)
        val totalInterest = maturity - principal

        return FdResult(
            investedAmount = principal,
            totalInterest = totalInterest.coerceAtLeast(0.0),
            maturityAmount = maturity
        )
    }

    /**
     * Calculate Recurring Deposit (RD) with quarterly compounding per monthly deposit:
     * A = sum_{m=1}^n [ P * (1 + r/4)^(4*(n - m + 1)/12) ]
     * @param monthlyDeposit Monthly deposit amount
     * @param annualRatePercent Annual interest rate %
     * @param tenureMonths Duration in total months
     */
    fun calculateRd(monthlyDeposit: Double, annualRatePercent: Double, tenureMonths: Int): RdResult {
        if (monthlyDeposit <= 0 || tenureMonths <= 0) {
            return RdResult(0.0, 0.0, 0.0)
        }
        val totalInvested = monthlyDeposit * tenureMonths
        if (annualRatePercent <= 0) {
            return RdResult(totalInvested, 0.0, totalInvested)
        }

        val rate = annualRatePercent / 100.0
        var maturity = 0.0
        for (m in 1..tenureMonths) {
            val monthsRemaining = (tenureMonths - m + 1).toDouble()
            val quarterExponent = (4.0 * monthsRemaining) / 12.0
            val depositFutureValue = monthlyDeposit * (1.0 + rate / 4.0).pow(quarterExponent)
            maturity += depositFutureValue
        }

        val totalInterest = (maturity - totalInvested).coerceAtLeast(0.0)
        return RdResult(
            investedAmount = totalInvested,
            totalInterest = totalInterest,
            maturityAmount = maturity
        )
    }

    /**
     * Calculate Discount
     */
    fun calculateDiscount(originalPrice: Double, discountPercent: Double): DiscountResult {
        val clampedDiscount = discountPercent.coerceIn(0.0, 100.0)
        if (originalPrice <= 0) {
            return DiscountResult(0.0, clampedDiscount, 0.0, 0.0)
        }
        val discountAmount = originalPrice * (clampedDiscount / 100.0)
        val finalPrice = (originalPrice - discountAmount).coerceAtLeast(0.0)

        return DiscountResult(
            originalPrice = originalPrice,
            discountPercent = clampedDiscount,
            discountAmount = discountAmount,
            finalPrice = finalPrice
        )
    }

    /**
     * Calculate GST
     * @param amount Base price or Total price depending on isInclusive
     * @param gstPercent GST rate % (e.g. 5, 12, 18, 28)
     * @param isInclusive True if input amount already includes GST
     */
    fun calculateGst(amount: Double, gstPercent: Double, isInclusive: Boolean): GstResult {
        val clampedRate = gstPercent.coerceAtLeast(0.0)
        if (amount <= 0) {
            return GstResult(0.0, 0.0, 0.0, 0.0, 0.0, isInclusive)
        }

        return if (isInclusive) {
            val netAmount = (amount * 100.0) / (100.0 + clampedRate)
            val gstAmount = amount - netAmount
            val halfGst = gstAmount / 2.0
            GstResult(
                netAmount = netAmount,
                gstAmount = gstAmount,
                cgstAmount = halfGst,
                sgstAmount = halfGst,
                totalAmount = amount,
                isInclusive = true
            )
        } else {
            val gstAmount = amount * (clampedRate / 100.0)
            val halfGst = gstAmount / 2.0
            val totalAmount = amount + gstAmount
            GstResult(
                netAmount = amount,
                gstAmount = gstAmount,
                cgstAmount = halfGst,
                sgstAmount = halfGst,
                totalAmount = totalAmount,
                isInclusive = false
            )
        }
    }
}
