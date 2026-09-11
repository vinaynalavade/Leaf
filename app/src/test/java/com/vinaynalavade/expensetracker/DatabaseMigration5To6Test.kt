package com.vinaynalavade.expensetracker

import androidx.sqlite.db.SupportSQLiteDatabase
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import com.vinaynalavade.expensetracker.data.local.entity.BudgetEntity
import com.vinaynalavade.expensetracker.data.local.entity.CategoryEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalContributionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitGroupEntity
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Proxy

class DatabaseMigration5To6Test {

    @Test
    fun testMigrationVersionNumbers() {
        assertEquals(5, ExpenseTrackerDatabase.MIGRATION_5_6.startVersion)
        assertEquals(6, ExpenseTrackerDatabase.MIGRATION_5_6.endVersion)
    }

    @Test
    fun testMigration5To6ExecutesAllRequiredStatements() {
        val executedStatements = mutableListOf<String>()
        val fakeDb = createRecordingDatabase(executedStatements)

        ExpenseTrackerDatabase.MIGRATION_5_6.migrate(fakeDb)

        val sqls = executedStatements

        // 1. Verify budgets table creation and indices
        val createBudgetsSql = sqls.firstOrNull { it.contains("CREATE TABLE `budgets`") }
        assertNotNull("CREATE TABLE budgets statement not found", createBudgetsSql)
        assertTrue(createBudgetsSql!!.contains("`amount_subunits` INTEGER NOT NULL"))
        assertTrue(createBudgetsSql.contains("`month` INTEGER NOT NULL"))
        assertTrue(createBudgetsSql.contains("`year` INTEGER NOT NULL"))
        assertTrue(createBudgetsSql.contains("FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL"))
        assertFalse("Must NOT use IF NOT EXISTS for budgets", createBudgetsSql.contains("IF NOT EXISTS"))

        assertTrue("Index budgets year/month missing", sqls.any { it.contains("index_budgets_year_month") && it.contains("`budgets` (`year`, `month`)") })
        assertTrue("Index budgets category_id missing", sqls.any { it.contains("index_budgets_category_id") && it.contains("`budgets` (`category_id`)") })
        assertTrue("Unique index overall budget missing", sqls.any { it.contains("index_budgets_overall_unique") && it.contains("WHERE `category_id` IS NULL") })
        assertTrue("Unique index category budget missing", sqls.any { it.contains("index_budgets_category_unique") && it.contains("WHERE `category_id` IS NOT NULL") })

        // 2. Verify savings_goals table creation
        val createSavingsGoalsSql = sqls.firstOrNull { it.contains("CREATE TABLE `savings_goals`") }
        assertNotNull("CREATE TABLE savings_goals statement not found", createSavingsGoalsSql)
        assertTrue(createSavingsGoalsSql!!.contains("`target_amount_subunits` INTEGER NOT NULL"))
        assertTrue(createSavingsGoalsSql.contains("`is_archived` INTEGER NOT NULL DEFAULT 0"))
        assertFalse("Must NOT use IF NOT EXISTS for savings_goals", createSavingsGoalsSql.contains("IF NOT EXISTS"))

        // 3. Verify savings_goal_contributions table creation and FK
        val createContributionsSql = sqls.firstOrNull { it.contains("CREATE TABLE `savings_goal_contributions`") }
        assertNotNull("CREATE TABLE savings_goal_contributions statement not found", createContributionsSql)
        assertTrue(createContributionsSql!!.contains("FOREIGN KEY(`goal_id`) REFERENCES `savings_goals`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE"))
        assertTrue(createContributionsSql.contains("`amount_subunits` INTEGER NOT NULL"))
        assertTrue("Index savings_goal_contributions goal_id missing", sqls.any { it.contains("index_savings_goal_contributions_goal_id") })
        assertFalse("Must NOT use IF NOT EXISTS for savings_goal_contributions", createContributionsSql.contains("IF NOT EXISTS"))

        // 4. Verify split_groups table creation
        val createSplitGroupsSql = sqls.firstOrNull { it.contains("CREATE TABLE `split_groups`") }
        assertNotNull("CREATE TABLE split_groups statement not found", createSplitGroupsSql)
        assertTrue(createSplitGroupsSql!!.contains("`name` TEXT NOT NULL"))
        assertTrue(createSplitGroupsSql.contains("`color_hex` TEXT NOT NULL DEFAULT '#3B82F6'"))
        assertFalse("Must NOT use IF NOT EXISTS for split_groups", createSplitGroupsSql.contains("IF NOT EXISTS"))

        // 5. Verify alter split_expenses and index
        val alterSplitExpensesSql = sqls.firstOrNull { it.contains("ALTER TABLE `split_expenses` ADD COLUMN `group_id`") }
        assertNotNull("ALTER TABLE split_expenses ADD COLUMN group_id missing", alterSplitExpensesSql)
        assertTrue(alterSplitExpensesSql!!.contains("REFERENCES `split_groups`(`id`) ON DELETE SET NULL"))
        assertTrue("Index split_expenses group_id missing", sqls.any { it.contains("index_split_expenses_group_id") && it.contains("`split_expenses` (`group_id`)") })
    }

    @Test
    fun testExistingSplitExpenseEntityMaintainsNullGroupIdByDefault() {
        val legacyExpenseEntity = SplitExpenseEntity(
            id = 101L,
            title = "Legacy Dinner",
            totalAmountSubunits = 50000L,
            date = 1700000000000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = "EQUAL",
            qrImagePath = null,
            addToTransactions = true,
            expenseTransactionId = 55L,
            paymentMethod = "ACCOUNT",
            groupId = null,
            createdAt = 1700000000000L,
            updatedAt = 1700000000000L
        )

        assertNull(legacyExpenseEntity.groupId)
        val domain = legacyExpenseEntity.toDomainModel(
            category = Category(1L, "Food", "restaurant", "#EF4444", TransactionType.EXPENSE, true),
            participants = emptyList()
        )
        assertEquals(101L, domain.id)
        assertEquals("Legacy Dinner", domain.title)
        assertEquals(50000L, domain.totalAmount.subunits)
        assertNull(domain.groupId)
    }

    @Test
    fun testSplitExpenseEntityWithGroupAssignment() {
        val group = SplitGroup(
            id = 5L,
            name = "Goa Trip",
            iconName = "beach_access",
            colorHex = "#10B981"
        )
        val groupEntity = SplitGroupEntity.fromDomainModel(group)
        assertEquals(5L, groupEntity.id)
        assertEquals("Goa Trip", groupEntity.name)

        val splitExpense = SplitExpense(
            id = 202L,
            title = "Resort Booking",
            totalAmount = Amount.fromSubunits(1200000L),
            date = 1710000000000L,
            categoryId = 2L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            groupId = group.id
        )

        val entity = SplitExpenseEntity.fromDomainModel(splitExpense)
        assertEquals(5L, entity.groupId)

        val reconstructedDomain = entity.toDomainModel(category = null, participants = emptyList())
        assertEquals(5L, reconstructedDomain.groupId)
    }

    @Test
    fun testBudgetEntityDomainMapping() {
        val budget = Budget(
            id = 1L,
            categoryId = 3L,
            amount = Amount.fromSubunits(2500000L),
            month = 9,
            year = 2026
        )

        val entity = BudgetEntity.fromDomainModel(budget)
        assertEquals(1L, entity.id)
        assertEquals(3L, entity.categoryId)
        assertEquals(2500000L, entity.amountSubunits)
        assertEquals(9, entity.month)
        assertEquals(2026, entity.year)

        val categoryEntity = CategoryEntity(3L, "Shopping", "shopping_bag", "#8B5CF6", "EXPENSE", true)
        val domainWithCategory = entity.toDomainModel(categoryEntity)
        assertEquals("Shopping", domainWithCategory.category?.name)
        assertFalse(domainWithCategory.isOverall)

        val overallBudget = Budget(
            id = 2L,
            categoryId = null,
            amount = Amount.fromSubunits(5000000L),
            month = 9,
            year = 2026
        )
        val overallEntity = BudgetEntity.fromDomainModel(overallBudget)
        assertNull(overallEntity.categoryId)
        assertTrue(overallEntity.toDomainModel(null).isOverall)
    }

    @Test
    fun testSavingsGoalEntityDomainMapping() {
        val goal = SavingsGoal(
            id = 10L,
            name = "Emergency Fund",
            targetAmount = Amount.fromSubunits(10000000L),
            targetDate = 1750000000000L,
            note = "6 months expenses",
            iconName = "shield",
            colorHex = "#3B82F6",
            isArchived = false
        )

        val entity = SavingsGoalEntity.fromDomainModel(goal)
        assertEquals(10L, entity.id)
        assertEquals("Emergency Fund", entity.name)
        assertEquals(10000000L, entity.targetAmountSubunits)
        assertEquals(1750000000000L, entity.targetDate)
        assertFalse(entity.isArchived)

        val contribution1 = SavingsGoalContributionEntity(
            id = 1L,
            goalId = 10L,
            amountSubunits = 4000000L,
            note = "Initial deposit",
            timestamp = 1710000000000L
        )
        val contribution2 = SavingsGoalContributionEntity(
            id = 2L,
            goalId = 10L,
            amountSubunits = 6000000L,
            note = "Bonus deposit",
            timestamp = 1710500000000L
        )

        val reconstructedGoal = entity.toDomainModel(listOf(contribution1, contribution2))
        assertEquals(10000000L, reconstructedGoal.currentSavedAmount.subunits)
        assertEquals(0L, reconstructedGoal.remainingAmount.subunits)
        assertEquals(100f, reconstructedGoal.progressPercentage, 0.001f)
        assertTrue(reconstructedGoal.isCompleted)
    }

    private fun createRecordingDatabase(executedStatements: MutableList<String>): SupportSQLiteDatabase {
        return Proxy.newProxyInstance(
            SupportSQLiteDatabase::class.java.classLoader,
            arrayOf(SupportSQLiteDatabase::class.java)
        ) { _, method, args ->
            if (method.name == "execSQL") {
                val sql = args?.getOrNull(0) as? String
                if (sql != null) {
                    executedStatements.add(sql.trim())
                }
                null
            } else if (method.name == "getVersion") {
                5
            } else if (method.returnType == java.lang.Boolean.TYPE) {
                false
            } else if (method.returnType == java.lang.Integer.TYPE) {
                0
            } else if (method.returnType == java.lang.Long.TYPE) {
                0L
            } else {
                null
            }
        } as SupportSQLiteDatabase
    }
}
