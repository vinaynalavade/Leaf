import Foundation

/// Pure Swift financial calculation engine executing high-precision fintech arithmetic.
/// Implements reducing-balance EMI schedules, SIP compound annuity-due with optional annual step-up,
/// term deposit (FD) and recurring deposit (RD) compounding, retail forward/reverse discounts,
/// and Indian Goods & Services Tax (GST) allocations.
///
/// Employs Swift `Decimal`-based arithmetic for monetary operations, currency-scale roundings,
/// and component reconciliation to eliminate IEEE-754 floating-point errors.
public enum FinancialCalculatorEngine {

    // MARK: - Precision Arithmetic Helpers

    /// Rounds a Decimal value to 2 decimal places using standard financial round-half-up (.plain) rounding.
    public static func roundCurrency(_ value: Decimal) -> Decimal {
        var initial = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &initial, 2, .plain)
        return rounded
    }

    /// Converts a Decimal value to a Double rounded strictly to 2 currency decimal places.
    public static func toCurrencyDouble(_ value: Decimal) -> Double {
        let rounded = roundCurrency(value)
        return NSDecimalNumber(decimal: rounded).doubleValue
    }

    /// Safely creates a Decimal from a Double for currency values, avoiding floating-point epsilon artifacts.
    public static func decimalFromCurrency(_ value: Double) -> Decimal {
        guard value.isFinite else { return Decimal.zero }
        let roundedDouble = (value * 100.0).rounded() / 100.0
        return Decimal(string: String(format: "%.2f", roundedDouble)) ?? Decimal(value)
    }

    // MARK: - 1. EMI Calculator (Reducing-Balance Amortisation)

    /// Calculates Equated Monthly Instalment (EMI), total interest, and month-by-month amortisation schedule.
    ///
    /// Formula:
    /// EMI = P × [r × (1 + r)^n] / [(1 + r)^n - 1]
    /// where P = principal, r = monthly rate (annualRate / 1200), n = tenure in months.
    ///
    /// Precision & Reconciliation:
    /// - All monetary components calculated with Decimal precision.
    /// - Monthly principal and interest components reconcile exactly with total payment:
    ///   Total Payment ≡ Total Principal + Total Interest down to the exact cent.
    /// - Month n absorbs any fractional cent rounding so remaining balance terminates at exactly 0.00.
    public static func calculateEmi(
        principal: Double,
        annualRatePercent: Double,
        tenureValue: Double,
        tenureUnit: EmiTenureUnit
    ) -> EmiResult {
        guard principal.isFinite, annualRatePercent.isFinite, tenureValue.isFinite else {
            return EmiResult.zero
        }
        guard principal > 0, tenureValue > 0 else {
            return EmiResult.zero
        }

        // Cap principal at ₹100 Billion (10,000 Crores) to prevent numeric overflow
        let clampedPrincipal = min(max(0.0, principal), 100_000_000_000.0)
        let principalDecimal = roundCurrency(decimalFromCurrency(clampedPrincipal))
        let principalDouble = toCurrencyDouble(principalDecimal)

        // Convert tenure to months (cap at 360 months / 30 years)
        let rawMonths: Double = (tenureUnit == .years) ? (tenureValue * 12.0) : tenureValue
        let totalMonths = min(max(1, Int(round(rawMonths))), 360)

        // Boundary: 0% Interest Loan
        if annualRatePercent <= 0.00001 {
            let emiDecimal = roundCurrency(principalDecimal / Decimal(totalMonths))
            let emiDouble = toCurrencyDouble(emiDecimal)

            var schedule: [EmiAmortizationMonth] = []
            var remainingDecimal = principalDecimal

            for m in 1...totalMonths {
                let pPaymentDecimal: Decimal
                if m == totalMonths {
                    pPaymentDecimal = remainingDecimal
                    remainingDecimal = Decimal.zero
                } else {
                    pPaymentDecimal = min(remainingDecimal, emiDecimal)
                    remainingDecimal -= pPaymentDecimal
                }

                let pPayment = toCurrencyDouble(pPaymentDecimal)
                let remBalance = toCurrencyDouble(remainingDecimal)

                schedule.append(EmiAmortizationMonth(
                    month: m,
                    principalPayment: pPayment,
                    interestPayment: 0.0,
                    totalPayment: pPayment,
                    remainingBalance: remBalance
                ))
            }

            return EmiResult(
                monthlyEmi: emiDouble,
                totalPrincipal: principalDouble,
                totalInterest: 0.0,
                totalPayment: principalDouble,
                principalRatio: 1.0,
                interestRatio: 0.0,
                amortizationSchedule: schedule
            )
        }

        // Standard positive rate loan
        let rateClamped = min(max(0.01, annualRatePercent), 100.0)
        let monthlyRateDouble = rateClamped / (12.0 * 100.0)
        let factorDouble = pow(1.0 + monthlyRateDouble, Double(totalMonths))

        guard factorDouble.isFinite, factorDouble > 1.0 else {
            return EmiResult.zero
        }

        let rawEmiDouble = principalDouble * (monthlyRateDouble * factorDouble) / (factorDouble - 1.0)
        let emiDecimal = roundCurrency(decimalFromCurrency(rawEmiDouble))
        let emiDouble = toCurrencyDouble(emiDecimal)

        var schedule: [EmiAmortizationMonth] = []
        var remainingDecimal = principalDecimal
        var totalInterestDecimal = Decimal.zero
        var totalPrincipalDecimal = Decimal.zero

        for m in 1...totalMonths {
            let remainingDouble = toCurrencyDouble(remainingDecimal)
            let rawInterestDouble = remainingDouble * monthlyRateDouble
            let interestMonthDecimal = roundCurrency(decimalFromCurrency(rawInterestDouble))

            let principalMonthDecimal: Decimal
            if m == totalMonths {
                principalMonthDecimal = remainingDecimal
                remainingDecimal = Decimal.zero
            } else {
                let computedPrincipal = max(Decimal.zero, emiDecimal - interestMonthDecimal)
                principalMonthDecimal = min(remainingDecimal, computedPrincipal)
                remainingDecimal -= principalMonthDecimal
            }

            totalInterestDecimal += interestMonthDecimal
            totalPrincipalDecimal += principalMonthDecimal

            let paymentMonthDecimal = principalMonthDecimal + interestMonthDecimal

            schedule.append(EmiAmortizationMonth(
                month: m,
                principalPayment: toCurrencyDouble(principalMonthDecimal),
                interestPayment: toCurrencyDouble(interestMonthDecimal),
                totalPayment: toCurrencyDouble(paymentMonthDecimal),
                remainingBalance: toCurrencyDouble(remainingDecimal)
            ))
        }

        let finalTotalInterest = toCurrencyDouble(totalInterestDecimal)
        let finalTotalPrincipal = toCurrencyDouble(totalPrincipalDecimal)
        let finalTotalPayment = toCurrencyDouble(totalPrincipalDecimal + totalInterestDecimal)

        let pRatio = finalTotalPayment > 0 ? (finalTotalPrincipal / finalTotalPayment) : 1.0
        let iRatio = finalTotalPayment > 0 ? (finalTotalInterest / finalTotalPayment) : 0.0

        return EmiResult(
            monthlyEmi: emiDouble,
            totalPrincipal: finalTotalPrincipal,
            totalInterest: finalTotalInterest,
            totalPayment: finalTotalPayment,
            principalRatio: pRatio,
            interestRatio: iRatio,
            amortizationSchedule: schedule
        )
    }

    // MARK: - 2. SIP Calculator (Compounding with Step-Up Support)

    /// Calculates Systematic Investment Plan (SIP) returns using beginning-of-month annuity-due compounding,
    /// with annual step-up contribution scaling.
    ///
    /// Standard Annuity-Due Model:
    /// Each monthly contribution m is deposited at the start of that month and compounds for
    /// (totalMonths - m + 1) monthly periods at the effective monthly rate (annualRate / 1200).
    ///
    /// Annual Step-Up:
    /// Monthly contribution scales by stepUpPercentage starting in Year 2 (month 13).
    ///
    /// Precision & Reconciliation:
    /// - Total Invested + Estimated Wealth Gained ≡ Total Projected Maturity Corpus.
    /// - All yearly milestones strictly reconcile invested + returns ≡ total corpus.
    public static func calculateSip(
        monthlyInvestment: Double,
        annualReturnPercent: Double,
        durationYears: Int,
        stepUpPercentage: Double = 0.0
    ) -> SipResult {
        guard monthlyInvestment.isFinite, annualReturnPercent.isFinite, stepUpPercentage.isFinite else {
            return SipResult.zero
        }
        guard monthlyInvestment > 0, durationYears > 0 else {
            return SipResult.zero
        }

        let clampedMonthlyDeposit = min(max(0.0, monthlyInvestment), 10_000_000.0) // ₹1 Crore/month max
        let clampedYears = min(max(1, durationYears), 50)
        let totalMonths = clampedYears * 12

        let clampedReturnRate = min(max(0.0, annualReturnPercent), 50.0)
        let monthlyRateDouble = clampedReturnRate / (12.0 * 100.0)
        let clampedStepUp = min(max(0.0, stepUpPercentage), 50.0)

        var runningMonthlyDepositDecimal = roundCurrency(decimalFromCurrency(clampedMonthlyDeposit))
        var runningInvestedDecimal = Decimal.zero
        var runningCorpusDouble: Double = 0.0
        var milestones: [SipYearlyMilestone] = []

        for year in 1...clampedYears {
            if year > 1 && clampedStepUp > 0 {
                let stepMultiplier = Decimal(1.0 + (clampedStepUp / 100.0))
                runningMonthlyDepositDecimal = roundCurrency(runningMonthlyDepositDecimal * stepMultiplier)
            }

            let monthlyDepositDouble = toCurrencyDouble(runningMonthlyDepositDecimal)

            for month in 1...12 {
                let globalMonth = ((year - 1) * 12) + month
                let monthsRemaining = totalMonths - globalMonth + 1

                runningInvestedDecimal += runningMonthlyDepositDecimal

                if monthlyRateDouble > 0 {
                    let futureValue = monthlyDepositDouble * pow(1.0 + monthlyRateDouble, Double(monthsRemaining))
                    runningCorpusDouble += futureValue
                } else {
                    runningCorpusDouble += monthlyDepositDouble
                }
            }

            // Record yearly growth milestone
            let yearInvested = toCurrencyDouble(runningInvestedDecimal)
            let yearCorpus = toCurrencyDouble(roundCurrency(decimalFromCurrency(runningCorpusDouble)))
            let yearReturns = max(0.0, toCurrencyDouble(decimalFromCurrency(yearCorpus) - decimalFromCurrency(yearInvested)))

            milestones.append(SipYearlyMilestone(
                year: year,
                investedAmount: yearInvested,
                estimatedReturns: yearReturns,
                totalCorpus: yearInvested + yearReturns
            ))
        }

        let totalInvested = toCurrencyDouble(runningInvestedDecimal)
        let rawCorpusDecimal = roundCurrency(decimalFromCurrency(runningCorpusDouble))

        let estimatedReturns: Double
        let totalCorpus: Double

        if clampedReturnRate <= 0.00001 {
            estimatedReturns = 0.0
            totalCorpus = totalInvested
        } else {
            let returnsDecimal = max(Decimal.zero, rawCorpusDecimal - runningInvestedDecimal)
            estimatedReturns = toCurrencyDouble(returnsDecimal)
            totalCorpus = toCurrencyDouble(runningInvestedDecimal + returnsDecimal)
        }

        let returnsRatio = totalCorpus > 0 ? (estimatedReturns / totalCorpus) : 0.0

        return SipResult(
            totalInvested: totalInvested,
            estimatedReturns: estimatedReturns,
            totalCorpus: totalCorpus,
            returnsRatio: returnsRatio,
            yearlyMilestones: milestones
        )
    }

    // MARK: - 3. Fixed Deposit (FD) Calculator

    /// Calculates term deposit interest and maturity with flexible compounding frequencies.
    ///
    /// Formula:
    /// A = P × (1 + r / f)^(f × t)
    /// where P = principal, r = annual rate, f = compounding frequency per year, t = tenure in years.
    /// Effective Annual Rate (EAR) = ((1 + r / f)^f - 1) × 100.
    ///
    /// Precision & Reconciliation:
    /// - Maturity Amount ≡ Principal Deposited + Total Interest Earned.
    public static func calculateFd(
        principal: Double,
        annualRatePercent: Double,
        tenureMonths: Int,
        compoundingFrequency: CompoundingFrequency = .quarterly
    ) -> FdResult {
        guard principal.isFinite, annualRatePercent.isFinite else {
            return FdResult.zero
        }
        guard principal > 0, tenureMonths > 0 else {
            return FdResult.zero
        }

        let clampedPrincipal = min(max(0.0, principal), 100_000_000_000.0)
        let principalDecimal = roundCurrency(decimalFromCurrency(clampedPrincipal))
        let principalDouble = toCurrencyDouble(principalDecimal)

        let clampedMonths = min(max(1, tenureMonths), 360)
        let tenureYears = Double(clampedMonths) / 12.0

        if annualRatePercent <= 0.00001 {
            return FdResult(
                investedAmount: principalDouble,
                totalInterest: 0.0,
                maturityAmount: principalDouble,
                effectiveAnnualRate: 0.0,
                compoundingFrequency: compoundingFrequency
            )
        }

        let rateClamped = min(max(0.01, annualRatePercent), 100.0)
        let rateDouble = rateClamped / 100.0
        let f = Double(compoundingFrequency.periodsPerYear)

        let maturityDouble = principalDouble * pow(1.0 + (rateDouble / f), f * tenureYears)
        let maturityDecimal = roundCurrency(decimalFromCurrency(maturityDouble))

        let interestDecimal = max(Decimal.zero, maturityDecimal - principalDecimal)
        let totalInterestFinal = toCurrencyDouble(interestDecimal)
        let maturityFinal = toCurrencyDouble(principalDecimal + interestDecimal)

        let earDouble = (pow(1.0 + (rateDouble / f), f) - 1.0) * 100.0

        return FdResult(
            investedAmount: principalDouble,
            totalInterest: totalInterestFinal,
            maturityAmount: maturityFinal,
            effectiveAnnualRate: max(0.0, earDouble),
            compoundingFrequency: compoundingFrequency
        )
    }

    // MARK: - 4. Recurring Deposit (RD) Calculator

    /// Calculates Recurring Deposit maturity using periodic monthly tranches compounded according to selected convention.
    ///
    /// Compounding Convention:
    /// In accordance with Indian Banks' Association (IBA) code, recurring deposits are compounded quarterly.
    /// Each monthly installment m (from 1 to n) is deposited at the start of that month and compounds for
    /// its exact individual duration: (n - m + 1) months until account maturity.
    ///
    /// Formula:
    /// Tranche Maturity_m = M × (1 + r / f)^(f × (n - m + 1) / 12)
    /// Maturity Corpus = Σ [ Tranche Maturity_m ]
    ///
    /// Precision & Reconciliation:
    /// - Total Invested = M × n
    /// - Maturity Amount ≡ Total Invested + Total Interest Earned down to the exact cent.
    public static func calculateRd(
        monthlyDeposit: Double,
        annualRatePercent: Double,
        tenureMonths: Int,
        compoundingFrequency: CompoundingFrequency = .quarterly
    ) -> RdResult {
        guard monthlyDeposit.isFinite, annualRatePercent.isFinite else {
            return RdResult.zero
        }
        guard monthlyDeposit > 0, tenureMonths > 0 else {
            return RdResult.zero
        }

        let clampedDeposit = min(max(0.0, monthlyDeposit), 10_000_000.0)
        let depositDecimal = roundCurrency(decimalFromCurrency(clampedDeposit))
        let depositDouble = toCurrencyDouble(depositDecimal)

        let clampedMonths = min(max(1, tenureMonths), 360)
        let totalInvestedDecimal = depositDecimal * Decimal(clampedMonths)
        let totalInvestedDouble = toCurrencyDouble(totalInvestedDecimal)

        if annualRatePercent <= 0.00001 {
            return RdResult(
                investedAmount: totalInvestedDouble,
                totalInterest: 0.0,
                maturityAmount: totalInvestedDouble,
                tenureMonths: clampedMonths,
                compoundingFrequency: compoundingFrequency
            )
        }

        let rateClamped = min(max(0.01, annualRatePercent), 100.0)
        let rateDouble = rateClamped / 100.0
        let f = Double(compoundingFrequency.periodsPerYear)

        var totalMaturityDouble: Double = 0.0

        // Compound each monthly installment for its specific individual duration: (clampedMonths - m + 1)
        for m in 1...clampedMonths {
            let monthsRemaining = Double(clampedMonths - m + 1)
            let exponent = (f * monthsRemaining) / 12.0
            let trancheMaturity = depositDouble * pow(1.0 + (rateDouble / f), exponent)
            totalMaturityDouble += trancheMaturity
        }

        let maturityDecimal = roundCurrency(decimalFromCurrency(totalMaturityDouble))
        let interestDecimal = max(Decimal.zero, maturityDecimal - totalInvestedDecimal)
        let totalInterestFinal = toCurrencyDouble(interestDecimal)
        let maturityFinal = toCurrencyDouble(totalInvestedDecimal + interestDecimal)

        return RdResult(
            investedAmount: totalInvestedDouble,
            totalInterest: totalInterestFinal,
            maturityAmount: maturityFinal,
            tenureMonths: clampedMonths,
            compoundingFrequency: compoundingFrequency
        )
    }

    // MARK: - 5. Discount Calculator (Forward & Reverse)

    /// Calculates forward retail discount (with optional successive discount) or reverse discount (price to percentage).
    ///
    /// Precision & Reconciliation:
    /// - Forward: Final Price + Total Savings ≡ Original Listing Price.
    /// - Reverse: Final Price + Savings Amount ≡ Original Listing Price.
    public static func calculateDiscount(
        originalPrice: Double,
        discountPercentage: Double,
        successiveDiscountPercentage: Double? = nil
    ) -> DiscountResult {
        guard originalPrice.isFinite, discountPercentage.isFinite else {
            return DiscountResult.zero
        }
        guard originalPrice > 0 else {
            return DiscountResult.zero
        }

        let origDecimal = roundCurrency(decimalFromCurrency(min(max(0.0, originalPrice), 100_000_000_000.0)))
        let origDouble = toCurrencyDouble(origDecimal)

        let d1Clamped = min(max(0.0, discountPercentage), 100.0)
        let d1Decimal = Decimal(d1Clamped)

        let step1DiscountDecimal = roundCurrency(origDecimal * (d1Decimal / Decimal(100)))
        let intermediatePriceDecimal = origDecimal - step1DiscountDecimal

        let effectiveDiscountDecimal: Decimal
        let totalDiscountDecimal: Decimal
        let finalPriceDecimal: Decimal

        if let succ = successiveDiscountPercentage, succ.isFinite, succ > 0.0 {
            let d2Clamped = min(max(0.0, succ), 100.0)
            let d2Decimal = Decimal(d2Clamped)

            let step2DiscountDecimal = roundCurrency(intermediatePriceDecimal * (d2Decimal / Decimal(100)))
            totalDiscountDecimal = min(origDecimal, step1DiscountDecimal + step2DiscountDecimal)
            finalPriceDecimal = max(Decimal.zero, origDecimal - totalDiscountDecimal)

            if origDecimal > Decimal.zero {
                effectiveDiscountDecimal = roundCurrency((totalDiscountDecimal / origDecimal) * Decimal(100))
            } else {
                effectiveDiscountDecimal = Decimal.zero
            }
        } else {
            totalDiscountDecimal = step1DiscountDecimal
            finalPriceDecimal = max(Decimal.zero, origDecimal - totalDiscountDecimal)
            effectiveDiscountDecimal = d1Decimal
        }

        let totalDiscountDouble = toCurrencyDouble(totalDiscountDecimal)
        let finalPriceDouble = toCurrencyDouble(finalPriceDecimal)
        let effectivePctDouble = NSDecimalNumber(decimal: effectiveDiscountDecimal).doubleValue

        return DiscountResult(
            originalPrice: origDouble,
            discountPercentage: d1Clamped,
            discountAmount: totalDiscountDouble,
            finalPrice: finalPriceDouble,
            savingsPercentage: effectivePctDouble,
            successiveDiscountPercentage: successiveDiscountPercentage,
            effectiveDiscountPercentage: effectivePctDouble
        )
    }

    /// Reverse discount calculation: computes discount amount and savings percentage given original price and final selling price.
    public static func calculateReverseDiscount(
        originalPrice: Double,
        finalPrice: Double
    ) -> DiscountResult {
        guard originalPrice.isFinite, finalPrice.isFinite else {
            return DiscountResult.zero
        }
        guard originalPrice > 0 else {
            return DiscountResult.zero
        }

        let origDecimal = roundCurrency(decimalFromCurrency(min(max(0.0, originalPrice), 100_000_000_000.0)))
        let origDouble = toCurrencyDouble(origDecimal)

        let finalClamped = min(max(0.0, finalPrice), origDouble)
        let finalDecimal = roundCurrency(decimalFromCurrency(finalClamped))
        let finalDouble = toCurrencyDouble(finalDecimal)

        let discountAmountDecimal = max(Decimal.zero, origDecimal - finalDecimal)
        let discountAmountDouble = toCurrencyDouble(discountAmountDecimal)

        let discountPercentage: Double
        if origDouble > 0 {
            discountPercentage = (discountAmountDouble / origDouble) * 100.0
        } else {
            discountPercentage = 0.0
        }

        return DiscountResult(
            originalPrice: origDouble,
            discountPercentage: discountPercentage,
            discountAmount: discountAmountDouble,
            finalPrice: finalDouble,
            savingsPercentage: discountPercentage,
            successiveDiscountPercentage: nil,
            effectiveDiscountPercentage: discountPercentage
        )
    }

    // MARK: - 6. Goods & Services Tax (GST) Calculator

    /// Calculates Indian GST tax liability with intra-state (CGST + SGST) vs inter-state (IGST) split,
    /// in both exclusive and inclusive computation modes.
    ///
    /// Precision & Reconciliation:
    /// - Exclusive: Final Amount ≡ Taxable Base + Total GST.
    /// - Inclusive: Final Gross Amount ≡ Taxable Base + Total GST.
    /// - Intra-State: CGST + SGST ≡ Total GST down to the exact cent/paisa (no split drift).
    /// - Inter-State: IGST ≡ Total GST.
    public static func calculateGst(
        amount: Double,
        gstRatePercent: Double,
        isInclusive: Bool,
        isInterState: Bool
    ) -> GstResult {
        guard amount.isFinite, gstRatePercent.isFinite else {
            return GstResult.zero
        }
        guard amount > 0 else {
            return GstResult.zero
        }

        let clampedAmount = min(max(0.0, amount), 100_000_000_000.0)
        let amountDecimal = roundCurrency(decimalFromCurrency(clampedAmount))
        let rateClamped = min(max(0.0, gstRatePercent), 100.0)
        let rateDecimal = Decimal(rateClamped)

        let taxableAmountDecimal: Decimal
        let totalGstDecimal: Decimal
        let finalAmountDecimal: Decimal

        if isInclusive {
            // Gross amount entered: Extract pre-tax base and embedded GST
            // Formula: Taxable = (Amount * 100) / (100 + Rate)
            taxableAmountDecimal = roundCurrency((amountDecimal * Decimal(100)) / (Decimal(100) + rateDecimal))
            totalGstDecimal = max(Decimal.zero, amountDecimal - taxableAmountDecimal)
            finalAmountDecimal = amountDecimal
        } else {
            // Pre-tax net amount entered: Add GST on top
            // Formula: GST = Taxable * (Rate / 100)
            taxableAmountDecimal = amountDecimal
            totalGstDecimal = roundCurrency(taxableAmountDecimal * (rateDecimal / Decimal(100)))
            finalAmountDecimal = taxableAmountDecimal + totalGstDecimal
        }

        // Apportion tax between CGST, SGST, IGST
        let cgstDecimal: Decimal
        let sgstDecimal: Decimal
        let igstDecimal: Decimal

        if isInterState {
            igstDecimal = totalGstDecimal
            cgstDecimal = Decimal.zero
            sgstDecimal = Decimal.zero
        } else {
            igstDecimal = Decimal.zero
            // Strict cent reconciliation: CGST + SGST must sum exactly to totalGstDecimal
            let halfGst = roundCurrency(totalGstDecimal / Decimal(2))
            cgstDecimal = halfGst
            sgstDecimal = max(Decimal.zero, totalGstDecimal - halfGst)
        }

        return GstResult(
            taxableAmount: toCurrencyDouble(taxableAmountDecimal),
            totalGst: toCurrencyDouble(totalGstDecimal),
            cgstAmount: toCurrencyDouble(cgstDecimal),
            sgstAmount: toCurrencyDouble(sgstDecimal),
            igstAmount: toCurrencyDouble(igstDecimal),
            finalAmount: toCurrencyDouble(finalAmountDecimal),
            gstRate: rateClamped,
            isInclusive: isInclusive,
            isInterState: isInterState
        )
    }
}
