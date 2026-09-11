package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetSavingsGoalsUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSavingsGoalContributionUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SavingsGoalProgressTest {

    private class FakeSavingsGoalRepository(
        private var goals: MutableList<SavingsGoal> = mutableListOf(),
        private var contributions: MutableList<SavingsGoalContribution> = mutableListOf()
    ) : SavingsGoalRepository {
        override fun getAllSavingsGoals(): Flow<List<SavingsGoal>> {
            return flowOf(goals.map { g ->
                val goalContribs = contributions.filter { it.goalId == g.id }
                g.copy(contributions = goalContribs)
            })
        }

        override fun getActiveSavingsGoals(): Flow<List<SavingsGoal>> {
            return flowOf(goals.filter { !it.isArchived }.map { g ->
                val goalContribs = contributions.filter { it.goalId == g.id }
                g.copy(contributions = goalContribs)
            })
        }

        override fun getArchivedSavingsGoals(): Flow<List<SavingsGoal>> {
            return flowOf(goals.filter { it.isArchived }.map { g ->
                val goalContribs = contributions.filter { it.goalId == g.id }
                g.copy(contributions = goalContribs)
            })
        }

        override fun getSavingsGoalById(id: Long): Flow<SavingsGoal?> {
            val g = goals.find { it.id == id }
            return flowOf(g?.let {
                val goalContribs = contributions.filter { it.goalId == g.id }
                it.copy(contributions = goalContribs)
            })
        }

        override suspend fun getSavingsGoalByIdSuspend(id: Long): SavingsGoal? {
            val g = goals.find { it.id == id } ?: return null
            val goalContribs = contributions.filter { it.goalId == g.id }
            return g.copy(contributions = goalContribs)
        }

        override suspend fun saveSavingsGoal(goal: SavingsGoal): AppResult<Long> {
            goals.removeAll { it.id == goal.id }
            goals.add(goal)
            return AppResult.Success(goal.id)
        }

        override suspend fun deleteSavingsGoal(id: Long): AppResult<Unit> {
            goals.removeAll { it.id == id }
            contributions.removeAll { it.goalId == id }
            return AppResult.Success(Unit)
        }

        override suspend fun setGoalArchived(id: Long, isArchived: Boolean): AppResult<Unit> {
            val idx = goals.indexOfFirst { it.id == id }
            if (idx != -1) {
                goals[idx] = goals[idx].copy(isArchived = isArchived)
            }
            return AppResult.Success(Unit)
        }

        override fun getContributionsForGoal(goalId: Long): Flow<List<SavingsGoalContribution>> {
            return flowOf(contributions.filter { it.goalId == goalId })
        }

        override suspend fun addContribution(contribution: SavingsGoalContribution): AppResult<Long> {
            val id = if (contribution.id != 0L) contribution.id else (contributions.size + 1).toLong()
            contributions.add(contribution.copy(id = id))
            return AppResult.Success(id)
        }

        override suspend fun updateContribution(contribution: SavingsGoalContribution): AppResult<Unit> {
            val idx = contributions.indexOfFirst { it.id == contribution.id }
            if (idx != -1) {
                contributions[idx] = contribution
            }
            return AppResult.Success(Unit)
        }

        override suspend fun deleteContribution(id: Long): AppResult<Unit> {
            contributions.removeAll { it.id == id }
            return AppResult.Success(Unit)
        }

        override suspend fun deleteAllGoals(): AppResult<Unit> {
            goals.clear()
            contributions.clear()
            return AppResult.Success(Unit)
        }
    }

    @Test
    fun `test derived completion and progress percentage`() = runBlocking {
        val goal = SavingsGoal(id = 1L, name = "MacBook", targetAmount = Amount.fromMainUnit(1000))
        val repo = FakeSavingsGoalRepository(mutableListOf(goal), mutableListOf())

        val getGoals = GetSavingsGoalsUseCase(repo)
        var list = emptyList<SavingsGoal>()
        getGoals.getAllGoals().collect { list = it }

        assertEquals(Amount.ZERO, list[0].currentSavedAmount)
        assertEquals(0f, list[0].progressPercentage, 0.001f)
        assertFalse(list[0].isCompleted)

        // Add 500
        val saveContrib = SaveSavingsGoalContributionUseCase(repo)
        val res1 = saveContrib(SavingsGoalContribution(id = 0L, goalId = 1L, amount = Amount.fromMainUnit(500), timestamp = System.currentTimeMillis()))
        assertTrue(res1 is AppResult.Success)

        getGoals.getAllGoals().collect { list = it }
        assertEquals(Amount.fromMainUnit(500), list[0].currentSavedAmount)
        assertEquals(50f, list[0].progressPercentage, 0.001f)
        assertFalse(list[0].isCompleted)

        // Add 500 more -> 1000 total (Completed)
        val res2 = saveContrib(SavingsGoalContribution(id = 0L, goalId = 1L, amount = Amount.fromMainUnit(500), timestamp = System.currentTimeMillis()))
        assertTrue(res2 is AppResult.Success)
        val secondContribId = (res2 as AppResult.Success).data

        getGoals.getAllGoals().collect { list = it }
        assertEquals(Amount.fromMainUnit(1000), list[0].currentSavedAmount)
        assertEquals(100f, list[0].progressPercentage, 0.001f)
        assertTrue(list[0].isCompleted)

        // Delete contribution 2 -> Should become incomplete again dynamically
        repo.deleteContribution(secondContribId)
        getGoals.getAllGoals().collect { list = it }
        assertEquals(Amount.fromMainUnit(500), list[0].currentSavedAmount)
        assertFalse(list[0].isCompleted)
    }

    @Test
    fun `test contribution validations`() = runBlocking {
        val goal = SavingsGoal(id = 1L, name = "Emergency Fund", targetAmount = Amount.fromMainUnit(5000), isArchived = false)
        val archivedGoal = SavingsGoal(id = 2L, name = "Old Goal", targetAmount = Amount.fromMainUnit(5000), isArchived = true)
        val repo = FakeSavingsGoalRepository(mutableListOf(goal, archivedGoal))
        val saveContrib = SaveSavingsGoalContributionUseCase(repo)

        // Non-positive amount
        val resZero = saveContrib(SavingsGoalContribution(goalId = 1L, amount = Amount.ZERO, timestamp = System.currentTimeMillis()))
        assertTrue(resZero is AppResult.Error)

        // Future timestamp
        val futureDate = System.currentTimeMillis() + 86400000L * 2
        val resFuture = saveContrib(SavingsGoalContribution(goalId = 1L, amount = Amount.fromMainUnit(100), timestamp = futureDate))
        assertTrue(resFuture is AppResult.Error)

        // Archived goal rejection
        val resArchived = saveContrib(SavingsGoalContribution(goalId = 2L, amount = Amount.fromMainUnit(100), timestamp = System.currentTimeMillis()))
        assertTrue(resArchived is AppResult.Error)
    }
}
