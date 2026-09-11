package com.vinaynalavade.expensetracker.presentation.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallSplit
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector
import com.vinaynalavade.expensetracker.R

sealed class Screen(
    val route: String,
    @StringRes val titleResId: Int = R.string.app_name,
    val icon: ImageVector? = null
) {
    data object Dashboard : Screen("dashboard", R.string.nav_dashboard, Icons.Default.Dashboard)
    data object Transactions : Screen("transactions?filter={filter}&query={query}", R.string.nav_transactions, Icons.AutoMirrored.Filled.ReceiptLong) {
        fun createRoute(filter: String? = null, query: String? = null): String {
            val f = filter ?: "ALL"
            val q = query ?: ""
            return "transactions?filter=$f&query=$q"
        }
    }
    data object Split : Screen("split", R.string.nav_split, Icons.AutoMirrored.Filled.CallSplit)
    data object Planning : Screen("planning", R.string.nav_planning, Icons.Default.Savings)
    data object Insights : Screen("insights", R.string.nav_insights, Icons.Default.PieChart)

    data object Analytics : Screen("monthly_summary", R.string.nav_analytics, Icons.Default.PieChart)
    data object Categories : Screen("categories", R.string.nav_categories, Icons.Default.Category)
    data object Settings : Screen("settings", R.string.nav_settings, Icons.Default.Settings)

    data object GoalDetail : Screen("goal_detail/{goalId}") {
        fun createRoute(goalId: Long) = "goal_detail/$goalId"
    }

    data object Tools : Screen("tools", R.string.tools_title, Icons.Default.Calculate)
    data object EmiCalculator : Screen("calculator_emi")
    data object SipCalculator : Screen("calculator_sip")
    data object FdCalculator : Screen("calculator_fd")
    data object RdCalculator : Screen("calculator_rd")
    data object DiscountCalculator : Screen("calculator_discount")
    data object GstCalculator : Screen("calculator_gst")

    data object CreateSplit : Screen("create_split")
    data object SplitDetail : Screen("split_detail/{splitId}") {
        fun createRoute(splitId: Long) = "split_detail/$splitId"
    }
    data object EditSplit : Screen("edit_split/{splitId}") {
        fun createRoute(splitId: Long) = "edit_split/$splitId"
    }

    data object Welcome : Screen("welcome")
    data object AppTour : Screen("app_tour")
    data object About : Screen("about")

    data object AddExpense : Screen("add_expense")
    data object AddIncome : Screen("add_income")

    data object TransactionDetail : Screen("transaction_detail/{transactionId}") {
        fun createRoute(transactionId: Long) = "transaction_detail/$transactionId"
    }

    data object EditTransaction : Screen("edit_transaction/{transactionId}") {
        fun createRoute(transactionId: Long) = "edit_transaction/$transactionId"
    }

    data object MonthlySummary : Screen("monthly_summary")
    data object RecurringTransactions : Screen("recurring_transactions")
    data object Statements : Screen("statements")
    data object Calendar : Screen("calendar")
    data object BackupRestore : Screen("backup_restore")
    data object AppLockSetup : Screen("app_lock_setup")
    data object ChangePin : Screen("change_pin")
}
