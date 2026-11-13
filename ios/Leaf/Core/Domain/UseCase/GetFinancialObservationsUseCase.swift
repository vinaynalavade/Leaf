import Foundation

/// Rule-based intelligence engine that synthesizes raw financial data into
/// actionable, genuine observations without AI hallucinations or synthetic placeholders.
public final class GetFinancialObservationsUseCase: Sendable {

    public init() {}

    public func execute(
        summaryResult: InsightsSummaryResult,
        budgets: [BudgetInsightItem],
        currency: Currency
    ) -> [FinancialObservation] {
        var observations: [FinancialObservation] = []

        let overview = summaryResult.financialOverview
        let stats = summaryResult.statistics
        let categories = summaryResult.categoryBreakdown

        // Rule 1: Budget Violations or Warnings (Highest Priority)
        let exceededBudgets = budgets.filter { $0.status == .exceeded }
        if let topExceeded = exceededBudgets.first {
            let catName = topExceeded.category?.name ?? "Total Budget"
            let overspendSubunits = topExceeded.spentAmount.subunits - topExceeded.limitAmount.subunits
            let overspendAmount = Amount(overspendSubunits)
            observations.append(FinancialObservation(
                id: "budget_exceeded_\(topExceeded.id)",
                type: .budgetExceeded,
                title: "\(catName) Limit Exceeded",
                message: "You've spent \(topExceeded.spentAmount.formatted(with: currency)), exceeding your \(topExceeded.limitAmount.formatted(with: currency)) budget by \(overspendAmount.formatted(with: currency)).",
                iconName: "exclamationmark.triangle.fill",
                sentiment: .critical,
                action: .budgets
            ))
        } else {
            let warningBudgets = budgets.filter { $0.status == .warning }
            if let topWarning = warningBudgets.first {
                let catName = topWarning.category?.name ?? "Budget"
                observations.append(FinancialObservation(
                    id: "budget_warning_\(topWarning.id)",
                    type: .budgetWarning,
                    title: "\(catName) Nearing Limit",
                    message: "\(catName) has reached \(String(format: "%.0f", topWarning.utilisationPercentage))% of its limit (\(topWarning.remainingAmount.formatted(with: currency)) remaining).",
                    iconName: "bell.badge.fill",
                    sentiment: .warning,
                    action: .budgets
                ))
            }
        }

        // Rule 2: Top Spending Category Dominance
        if let topCat = categories.first, topCat.amount.subunits > 0 {
            if topCat.percentageOfTotal >= 28.0 && categories.count >= 2 {
                observations.append(FinancialObservation(
                    id: "top_category_\(topCat.id)",
                    type: .highestCategory,
                    title: "Largest Expense: \(topCat.category.name)",
                    message: "\(topCat.category.name) accounts for \(String(format: "%.1f", topCat.percentageOfTotal))% of your spending (\(topCat.amount.formatted(with: currency))) across \(topCat.transactionCount) transactions.",
                    iconName: topCat.category.iconName.isEmpty ? "chart.pie.fill" : topCat.category.iconName,
                    sentiment: .neutral,
                    action: .category(categoryId: topCat.id)
                ))
            }
        }

        // Rule 3: Category Surge Alert
        let surgingCategories = categories.filter {
            guard let change = $0.changePercentageVsPrevious, let prev = $0.previousPeriodAmount else { return false }
            return change >= 20.0 && ($0.amount.subunits - prev.subunits) >= 1500 // Min $15 increase
        }
        if let topSurge = surgingCategories.max(by: { ($0.changePercentageVsPrevious ?? 0) < ($1.changePercentageVsPrevious ?? 0) }) {
            let pctStr = String(format: "+%.0f%%", topSurge.changePercentageVsPrevious ?? 0)
            observations.append(FinancialObservation(
                id: "surge_\(topSurge.id)",
                type: .categorySurge,
                title: "\(topSurge.category.name) Spending Surge",
                message: "Spending in \(topSurge.category.name) increased by \(pctStr) compared to the previous period (\(topSurge.amount.formatted(with: currency))).",
                iconName: "arrow.up.right.circle.fill",
                sentiment: .warning,
                action: .category(categoryId: topSurge.id)
            ))
        }

        // Rule 4: Spending Reduction Win (Savings Win)
        let reducedCategories = categories.filter {
            guard let change = $0.changePercentageVsPrevious, let prev = $0.previousPeriodAmount else { return false }
            return change <= -15.0 && (prev.subunits - $0.amount.subunits) >= 1500 // Min $15 reduced
        }
        if let topReduced = reducedCategories.min(by: { ($0.changePercentageVsPrevious ?? 0) < ($1.changePercentageVsPrevious ?? 0) }) {
            let savedAmount = Amount((topReduced.previousPeriodAmount?.subunits ?? 0) - topReduced.amount.subunits)
            let pctStr = String(format: "%.0f%%", abs(topReduced.changePercentageVsPrevious ?? 0))
            observations.append(FinancialObservation(
                id: "reduction_\(topReduced.id)",
                type: .spendingReduction,
                title: "\(topReduced.category.name) Spending Reduced",
                message: "Great job! You cut \(topReduced.category.name) expenses by \(pctStr), saving \(savedAmount.formatted(with: currency)) vs last period.",
                iconName: "arrow.down.right.circle.fill",
                sentiment: .positive,
                action: .category(categoryId: topReduced.id)
            ))
        }

        // Rule 5: Peak Spending Day
        if let peakDay = stats.highestSpendingDay, stats.dailyAverageExpense.subunits > 0 {
            let ratio = Double(peakDay.amount.subunits) / Double(stats.dailyAverageExpense.subunits)
            if ratio >= 2.0 && peakDay.amount.subunits >= 2500 { // 2x daily average & >= $25
                observations.append(FinancialObservation(
                    id: "peak_day_\(Int64(peakDay.date.timeIntervalSince1970))",
                    type: .peakSpendingDay,
                    title: "Peak Day: \(peakDay.formattedDate)",
                    message: "Spending peaked on \(peakDay.formattedDate) at \(peakDay.amount.formatted(with: currency)) (\(String(format: "%.1f", ratio))x your daily average).",
                    iconName: "calendar.badge.clock",
                    sentiment: .neutral,
                    action: .date(peakDay.date)
                ))
            }
        }

        // Rule 6: Positive Operating Cash Flow & Unspent Income Rate
        if overview.earnedIncome.subunits > 0 && overview.operatingCashFlow.subunits > 0 && overview.unspentIncomeRate >= 15.0 {
            observations.append(FinancialObservation(
                id: "cashflow_health",
                type: .healthyCashFlow,
                title: "Positive Operating Cash Flow",
                message: "You retained \(String(format: "%.1f", overview.unspentIncomeRate))% of your earned income this period (+\(overview.operatingCashFlow.formatted(with: currency)) cash surplus).",
                iconName: "leaf.fill",
                sentiment: .positive,
                action: nil
            ))
        }

        // Rule 7: Actual Savings Contribution Rate Milestone
        if overview.earnedIncome.subunits > 0 && overview.actualSavingsRate >= 10.0 {
            observations.append(FinancialObservation(
                id: "savings_rate_milestone",
                type: .savingsMilestone,
                title: "Active Goal Contributions",
                message: "You allocated \(String(format: "%.1f", overview.actualSavingsRate))% of your income into savings goals (+\(overview.netSavingsContributions.formatted(with: currency)) net deposits).",
                iconName: "sparkles",
                sentiment: .positive,
                action: nil
            ))
        }

        // Rule 8: Savings Goals Momentum
        let activeGoals = overview.savingsSummary.goals
        if let topGoal = activeGoals.first(where: { $0.progressPercentage >= 100.0 }) {
            observations.append(FinancialObservation(
                id: "goal_completed_\(topGoal.id)",
                type: .savingsMilestone,
                title: "\(topGoal.goal.name) Fully Funded!",
                message: "Congratulations! You have reached 100% of your target with \(topGoal.currentAmount.formatted(with: currency)) saved.",
                iconName: "checkmark.seal.fill",
                sentiment: .positive,
                action: .savingsGoal(goalId: topGoal.id)
            ))
        } else if let progressGoal = activeGoals.first(where: { $0.periodContributionsTotal.subunits > 0 }) {
            observations.append(FinancialObservation(
                id: "goal_progress_\(progressGoal.id)",
                type: .savingsMilestone,
                title: "\(progressGoal.goal.name) Progress",
                message: "Added \(progressGoal.periodContributionsTotal.formatted(with: currency)) this period. Currently at \(String(format: "%.0f", progressGoal.progressPercentage))% of target.",
                iconName: "target",
                sentiment: .positive,
                action: .savingsGoal(goalId: progressGoal.id)
            ))
        }

        return observations
    }
}

