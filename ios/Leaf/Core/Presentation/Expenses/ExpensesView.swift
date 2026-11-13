import SwiftUI

/// Primary native iOS screen for the Expenses module.
/// Encapsulates monthly period navigation, monthly burn rate summary, category spending breakdown,
/// multi-criteria filtering, search, and date-grouped transaction history with add/edit/delete flows.
public struct ExpensesView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: ExpensesViewModel?
    @State private var categories: [Category] = []
    @State private var searchText: String = ""
    @State private var isScanReceiptPresented: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                @Bindable var vm = vm
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header with Month Picker & Action Controls
                        ExpensesMonthPickerHeaderView(
                            periodText: vm.formattedPeriod,
                            isSearchActive: vm.isSearchActive,
                            activeFilterCount: vm.filter.activeFilterCount + (vm.selectedCategoryForFilter != nil ? 1 : 0),
                            onPreviousMonth: {
                                Task { await vm.previousMonth() }
                            },
                            onNextMonth: {
                                Task { await vm.nextMonth() }
                            },
                            onToggleSearch: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    vm.isSearchActive.toggle()
                                    if !vm.isSearchActive {
                                        searchText = ""
                                        Task {
                                            vm.filter.searchQuery = ""
                                            await vm.loadData()
                                        }
                                    }
                                }
                            },
                            onOpenFilter: {
                                vm.isFilterSheetPresented = true
                            },
                            onScanReceipt: {
                                isScanReceiptPresented = true
                            },
                            onAddExpense: {
                                vm.isAddExpenseSheetPresented = true
                            }
                        )
                        .padding(.top, 4)

                        // 2. Expandable Search Bar & Filter Indicators
                        if vm.isSearchActive || vm.filter.isActive || vm.selectedCategoryForFilter != nil {
                            ExpensesSearchBarView(
                                searchText: $searchText,
                                filter: vm.filter,
                                selectedCategory: vm.selectedCategoryForFilter,
                                onClearSearch: {
                                    searchText = ""
                                    Task {
                                        vm.filter.searchQuery = ""
                                        await vm.loadData()
                                    }
                                },
                                onClearCategory: {
                                    Task { await vm.selectCategoryFilter(nil) }
                                },
                                onClearAllFilters: {
                                    searchText = ""
                                    Task { await vm.clearFilters() }
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 3. Monthly Financial Summary Card
                        ExpensesMonthlySummaryCardView(
                            summary: vm.monthlySummary,
                            currency: vm.selectedCurrency
                        )

                        // 4. Category Spending Breakdown
                        ExpensesCategoryBreakdownView(
                            breakdowns: vm.categoryBreakdowns,
                            selectedCategory: vm.selectedCategoryForFilter,
                            currency: vm.selectedCurrency,
                            onSelectCategory: { cat in
                                Task { await vm.selectCategoryFilter(cat) }
                            },
                            onClearCategoryFilter: {
                                Task { await vm.selectCategoryFilter(nil) }
                            }
                        )

                        // 4b. Fast Ledger Filter Chips (All, Cash, Account)
                        HStack(spacing: 8) {
                            ledgerChip(title: "All", method: nil, vm: vm)
                            ledgerChip(title: "💵 Cash", method: .cash, vm: vm)
                            ledgerChip(title: "💳 Account", method: .account, vm: vm)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // 5. Date-Grouped Transaction History
                        ExpensesTransactionHistoryView(
                            groupedTransactions: vm.groupedTransactions,
                            currency: vm.selectedCurrency,
                            isFilterActive: vm.filter.isActive || vm.selectedCategoryForFilter != nil,
                            onEditTransaction: { tx in
                                vm.transactionToEdit = tx
                            },
                            onRequestDelete: { tx in
                                vm.transactionToDelete = tx
                            },
                            onAddExpense: {
                                vm.isAddExpenseSheetPresented = true
                            },
                            onClearFilters: {
                                searchText = ""
                                Task { await vm.clearFilters() }
                            }
                        )

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 4)
                }
                .refreshable {
                    await vm.loadData()
                }
                // Sheet: Add New Expense
                .sheet(isPresented: $vm.isAddExpenseSheetPresented) {
                    AddEditExpenseSheet(
                        transaction: nil,
                        currency: vm.selectedCurrency,
                        categories: categories,
                        onSaveWithCurrency: { primaryAmt, catId, method, note, timestamp, receiptPath, origAmt, currCode, rate, walletId in
                            try await vm.addExpense(
                                amount: primaryAmt,
                                categoryId: catId,
                                paymentMethod: method,
                                note: note,
                                timestamp: timestamp,
                                receiptImagePath: receiptPath,
                                originalAmount: origAmt,
                                currencyCode: currCode,
                                exchangeRate: rate,
                                travelWalletId: walletId
                            )
                        }
                    )
                }
                // Sheet: Edit Existing Expense
                .sheet(item: $vm.transactionToEdit) { tx in
                    AddEditExpenseSheet(
                        transaction: tx,
                        currency: vm.selectedCurrency,
                        categories: categories,
                        onSaveWithCurrency: { primaryAmt, catId, method, note, timestamp, receiptPath, origAmt, currCode, rate, walletId in
                            try await vm.updateExpense(
                                id: tx.id,
                                amount: primaryAmt,
                                categoryId: catId,
                                paymentMethod: method,
                                note: note,
                                timestamp: timestamp,
                                receiptImagePath: receiptPath,
                                originalAmount: origAmt,
                                currencyCode: currCode,
                                exchangeRate: rate,
                                travelWalletId: walletId
                            )
                        },
                        onDelete: { id in
                            await vm.deleteExpense(id: id)
                        }
                    )
                }
                // Sheet: Multi-Criteria Filter
                .sheet(isPresented: $vm.isFilterSheetPresented) {
                    ExpensesFilterSheet(
                        categories: categories,
                        initialFilter: vm.filter,
                        currency: vm.selectedCurrency,
                        onApply: { appliedFilter in
                            Task { await vm.applyFilter(appliedFilter) }
                        }
                    )
                }
                // Sheet: Receipt Scanner OCR
                .sheet(isPresented: $isScanReceiptPresented) {
                    ReceiptScannerSheet(
                        processReceiptImageUseCase: container.processReceiptImageUseCase,
                        addTransactionUseCase: container.addTransactionUseCase,
                        currency: vm.selectedCurrency,
                        categories: categories,
                        onSaveComplete: {
                            Task { await vm.loadData() }
                        }
                    )
                }
                // Delete Confirmation Alert for list swipe / context menu
                .confirmationDialog(
                    "Delete Expense?",
                    isPresented: Binding(
                        get: { vm.transactionToDelete != nil },
                        set: { if !$0 { vm.transactionToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    if let tx = vm.transactionToDelete {
                        Button("Delete Expense", role: .destructive) {
                            Task { await vm.deleteExpense(id: tx.id) }
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        vm.transactionToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this expense? This action cannot be undone.")
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            if viewModel == nil {
                let vm = ExpensesViewModel(
                    getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
                    getCategorySpendingUseCase: container.getCategorySpendingUseCase,
                    getTransactionsUseCase: container.getTransactionsUseCase,
                    addTransactionUseCase: container.addTransactionUseCase,
                    updateTransactionUseCase: container.updateTransactionUseCase,
                    deleteTransactionUseCase: container.deleteTransactionUseCase,
                    preferencesRepository: container.preferencesRepository
                )
                self.viewModel = vm
                await vm.loadData()

                if let loadedCategories = try? await container.categoryRepository.getAllCategories() {
                    self.categories = loadedCategories
                }
            } else {
                await viewModel?.loadData()
            }
        }
        .onChange(of: searchText) { _, newText in
            guard let vm = viewModel else { return }
            vm.filter.searchQuery = newText
            Task { await vm.loadData() }
        }
    }

    @ViewBuilder
    private func ledgerChip(title: String, method: PaymentMethod?, vm: ExpensesViewModel) -> some View {
        let isSelected = vm.filter.paymentMethod == method
        Button(action: {
            Task {
                var updated = vm.filter
                updated.paymentMethod = method
                await vm.applyFilter(updated)
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : LeafTheme.textPrimary(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? LeafTheme.brandEmerald : LeafTheme.card(for: colorScheme))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : LeafTheme.border(for: colorScheme), lineWidth: 0.75)
                )
        }
        .buttonStyle(.plain)
    }
}

