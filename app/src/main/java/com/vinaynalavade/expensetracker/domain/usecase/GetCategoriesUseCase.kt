package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * UseCase to retrieve categories by type or all categories.
 * By default, internal system categories (e.g. "Savings & Goals") are excluded
 * to protect normal manual user expense categorization.
 */
class GetCategoriesUseCase(
    private val categoryRepository: CategoryRepository
) {
    operator fun invoke(includeInternal: Boolean = false): Flow<List<Category>> =
        categoryRepository.getCategories().map { list ->
            if (includeInternal) list else list.filter { !it.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true) }
        }

    fun getByType(type: TransactionType, includeInternal: Boolean = false): Flow<List<Category>> =
        categoryRepository.getCategoriesByType(type).map { list ->
            if (includeInternal) list else list.filter { !it.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true) }
        }
}
