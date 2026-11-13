import Foundation

/// UseCase retrieving travel wallets with calculated spending totals in both wallet currency and primary currency.
public final class GetTravelWalletsUseCase: Sendable {

    private let walletRepository: TravelWalletRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        walletRepository: TravelWalletRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.walletRepository = walletRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    public func execute() async throws -> [TravelWalletSummary] {
        let wallets = try await walletRepository.getAllWallets()
        var summaries: [TravelWalletSummary] = []

        for wallet in wallets {
            let txs = try await transactionRepository.getTransactionsForWallet(walletId: wallet.id)
            let expenses = txs.filter { $0.type == .expense && !$0.isInternalTransfer }

            // 1. Total spent in wallet currency
            var walletSubunits: Int64 = 0
            for exp in expenses {
                if exp.currencyCode.caseInsensitiveCompare(wallet.currencyCode) == .orderedSame {
                    walletSubunits += exp.originalAmount.subunits
                } else {
                    // Convert to wallet currency if transaction was logged in another currency
                    let converted = CurrencyConverter.convert(
                        amount: exp.originalAmount,
                        from: exp.originalCurrency,
                        to: wallet.currency,
                        rate: CurrencyConverter.estimatedRate(from: exp.currencyCode, to: wallet.currencyCode)
                    )
                    walletSubunits += converted.subunits
                }
            }

            // 2. Total spent in primary currency (using stored primary amount equivalents)
            let primarySubunits = expenses.reduce(Int64(0)) { $0 + $1.amount.subunits }

            // 3. Category spending breakdown for this wallet
            var categoryMap: [Int64: Int64] = [:]
            for exp in expenses {
                categoryMap[exp.categoryId, default: 0] += exp.originalAmount.subunits
            }

            var catSpendings: [CategorySpending] = []
            var txCountMap: [Int64: Int] = [:]
            for exp in expenses {
                txCountMap[exp.categoryId, default: 0] += 1
            }
            for (catId, subunits) in categoryMap {
                if let cat = try? await categoryRepository.getCategory(id: catId) {
                    let pct = walletSubunits > 0 ? (Double(subunits) / Double(walletSubunits)) * 100.0 : 0.0
                    catSpendings.append(
                        CategorySpending(
                            category: cat,
                            totalAmount: Amount(subunits: subunits),
                            transactionCount: txCountMap[catId, default: 0],
                            percentageOfTotal: pct
                        )
                    )
                }
            }
            catSpendings.sort { (a: CategorySpending, b: CategorySpending) -> Bool in
                a.totalAmount.subunits > b.totalAmount.subunits
            }

            summaries.append(
                TravelWalletSummary(
                    wallet: wallet,
                    totalSpentInWalletCurrency: Amount(subunits: walletSubunits),
                    totalSpentInPrimaryCurrency: Amount(subunits: primarySubunits),
                    transactionCount: expenses.count,
                    categorySpendings: catSpendings
                )
            )
        }

        return summaries
    }

    public func getWalletSummary(id: Int64) async throws -> TravelWalletSummary? {
        let all = try await execute()
        return all.first { $0.wallet.id == id }
    }
}

