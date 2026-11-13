import Foundation
import SwiftUI

/// Central Dependency Injection container for Leaf on iOS.
/// Initializes the SQLite database, repositories, and use cases.
@Observable
public final class AppContainer: @unchecked Sendable {

    public let database: AppDatabase
    public let transactionRepository: TransactionRepositoryProtocol
    public let categoryRepository: CategoryRepositoryProtocol
    public let splitRepository: SplitRepositoryProtocol
    public let budgetRepository: BudgetRepositoryProtocol
    public let savingsGoalRepository: SavingsGoalRepositoryProtocol
    public let preferencesRepository: UserPreferencesRepositoryProtocol
    public let statementRepository: StatementRepositoryProtocol

    public let addTransactionUseCase: AddTransactionUseCase
    public let updateTransactionUseCase: UpdateTransactionUseCase
    public let getTransactionsUseCase: GetTransactionsUseCase
    public let deleteTransactionUseCase: DeleteTransactionUseCase
    public let reverseTransferUseCase: ReverseTransferUseCase
    public let calculateSplitUseCase: CalculateSplitUseCase
    public let settleParticipantUseCase: SettleParticipantUseCase
    public let createSplitExpenseUseCase: CreateSplitExpenseUseCase
    public let updateSplitExpenseUseCase: UpdateSplitExpenseUseCase
    public let deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase
    public let getSplitSummaryUseCase: GetSplitSummaryUseCase
    public let recordParticipantPaymentUseCase: RecordParticipantPaymentUseCase
    public let reverseParticipantPaymentUseCase: ReverseParticipantPaymentUseCase
    public let getSplitGroupAnalyticsUseCase: GetSplitGroupAnalyticsUseCase
    public let getSplitGroupsUseCase: GetSplitGroupsUseCase
    public let saveSplitGroupUseCase: SaveSplitGroupUseCase
    public let deleteSplitGroupUseCase: DeleteSplitGroupUseCase
    public let getFinancialSummaryUseCase: GetFinancialSummaryUseCase
    public let getBudgetProgressUseCase: GetBudgetProgressUseCase
    public let saveBudgetUseCase: SaveBudgetUseCase
    public let deleteBudgetUseCase: DeleteBudgetUseCase
    public let getSavingsGoalsUseCase: GetSavingsGoalsUseCase
    public let saveSavingsGoalUseCase: SaveSavingsGoalUseCase
    public let deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase
    public let setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase
    public let recordSavingsContributionUseCase: RecordSavingsContributionUseCase
    public let reverseSavingsContributionUseCase: ReverseSavingsContributionUseCase
    public let recordSavingsWithdrawalUseCase: RecordSavingsWithdrawalUseCase
    public let reverseSavingsWithdrawalUseCase: ReverseSavingsWithdrawalUseCase
    public let getMonthlyExpenseSummaryUseCase: GetMonthlyExpenseSummaryUseCase
    public let getCategorySpendingUseCase: GetCategorySpendingUseCase

    // MARK: - Insights & Analytics Use Cases
    public let getCategoryAnalysisUseCase: GetCategoryAnalysisUseCase
    public let getSpendingTrendsUseCase: GetSpendingTrendsUseCase
    public let getBudgetInsightsUseCase: GetBudgetInsightsUseCase
    public let getSavingsInsightsUseCase: GetSavingsInsightsUseCase
    public let getInsightsSummaryUseCase: GetInsightsSummaryUseCase
    public let getFinancialObservationsUseCase: GetFinancialObservationsUseCase

    // MARK: - Statements & Export Services & Use Cases
    public let pdfStatementGenerator: PdfStatementGenerator
    public let csvStatementGenerator: CsvStatementGenerator
    public let compileStatementDataUseCase: CompileStatementDataUseCase
    public let generateStatementUseCase: GenerateStatementUseCase
    public let deleteStatementUseCase: DeleteStatementUseCase
    public let getStatementsUseCase: GetStatementsUseCase

    // MARK: - Financial Tools & Calculators Use Cases
    public let calculateEmiUseCase: CalculateEmiUseCase
    public let calculateSipUseCase: CalculateSipUseCase
    public let calculateFdUseCase: CalculateFdUseCase
    public let calculateRdUseCase: CalculateRdUseCase
    public let calculateDiscountUseCase: CalculateDiscountUseCase
    public let calculateGstUseCase: CalculateGstUseCase

    // MARK: - Recurring Transactions & Bill Reminders
    public let recurringRepository: RecurringRepositoryProtocol
    public let notificationService: NotificationService
    public let createRecurringTransactionUseCase: CreateRecurringTransactionUseCase
    public let updateRecurringTransactionUseCase: UpdateRecurringTransactionUseCase
    public let pauseRecurringTransactionUseCase: PauseRecurringTransactionUseCase
    public let resumeRecurringTransactionUseCase: ResumeRecurringTransactionUseCase
    public let cancelRecurringTransactionUseCase: CancelRecurringTransactionUseCase
    public let deleteRecurringTransactionUseCase: DeleteRecurringTransactionUseCase
    public let generateDueOccurrencesUseCase: GenerateDueOccurrencesUseCase
    public let getRecurringTransactionsUseCase: GetRecurringTransactionsUseCase
    public let getUpcomingBillsUseCase: GetUpcomingBillsUseCase
    public let markBillAsPaidUseCase: MarkBillAsPaidUseCase
    public let reversePaidOccurrenceUseCase: ReversePaidOccurrenceUseCase
    public let skipBillOccurrenceUseCase: SkipBillOccurrenceUseCase
    public let snoozeBillReminderUseCase: SnoozeBillReminderUseCase
    public let getSubscriptionSummaryUseCase: GetSubscriptionSummaryUseCase

    // Phase 9: Security, Privacy & Backup
    public let keychainService: KeychainService
    public let backupCryptoEngine: BackupCryptoEngine
    public let backupService: BackupService
    public let appLockService: AppLockService
    public let createBackupUseCase: CreateBackupUseCase
    public let validateBackupUseCase: ValidateBackupUseCase
    public let restoreBackupUseCase: RestoreBackupUseCase
    public let deleteAllFinancialDataUseCase: DeleteAllFinancialDataUseCase
    public let googleAuthService: GoogleAuthServiceProtocol
    public let googleDriveBackupService: GoogleDriveBackupService

    // MARK: - Receipt OCR & Scanning Services & Use Cases
    public let receiptOCRService: ReceiptOCRServiceProtocol
    public let receiptStorageService: ReceiptStorageService
    public let processReceiptImageUseCase: ProcessReceiptImageUseCase

    // MARK: - Phase 12: Multi-Currency & Travel Wallets
    public let exchangeRateRepository: ExchangeRateRepositoryProtocol
    public let travelWalletRepository: TravelWalletRepositoryProtocol
    public let getExchangeRatesUseCase: GetExchangeRatesUseCase
    public let saveExchangeRateUseCase: SaveExchangeRateUseCase
    public let changePrimaryCurrencyUseCase: ChangePrimaryCurrencyUseCase
    public let getTravelWalletsUseCase: GetTravelWalletsUseCase
    public let saveTravelWalletUseCase: SaveTravelWalletUseCase
    public let deleteTravelWalletUseCase: DeleteTravelWalletUseCase

    // MARK: - Appearance & Theme Mode
    public var currentThemeMode: String = "SYSTEM"

    public var themeColorScheme: ColorScheme? {
        switch currentThemeMode.uppercased() {
        case "LIGHT":
            return .light
        case "DARK":
            return .dark
        default:
            return nil
        }
    }

    public func setThemeMode(_ mode: String) {
        currentThemeMode = mode
        preferencesRepository.setThemeMode(mode)
    }

    public init(
        database: AppDatabase,
        preferencesRepository: UserPreferencesRepositoryProtocol = UserPreferencesRepository()
    ) {
        self.database = database
        self.preferencesRepository = preferencesRepository
        self.currentThemeMode = preferencesRepository.getUserPreferences().themeMode

        let txRepo = GRDBTransactionRepository(database: database)
        let catRepo = GRDBCategoryRepository(database: database)
        let splitRepo = GRDBSplitRepository(database: database)
        let budgetRepo = GRDBBudgetRepository(database: database)
        let savingsRepo = GRDBSavingsGoalRepository(database: database)
        let statementRepo = GRDBStatementRepository(database: database)
        let recurringRepo = GRDBRecurringRepository(database: database)
        let notifService = NotificationService.shared

        self.transactionRepository = txRepo
        self.categoryRepository = catRepo
        self.splitRepository = splitRepo
        self.budgetRepository = budgetRepo
        self.savingsGoalRepository = savingsRepo
        self.statementRepository = statementRepo
        self.recurringRepository = recurringRepo
        self.notificationService = notifService

        self.addTransactionUseCase = AddTransactionUseCase(transactionRepository: txRepo, categoryRepository: catRepo)
        self.updateTransactionUseCase = UpdateTransactionUseCase(transactionRepository: txRepo, categoryRepository: catRepo)
        self.getTransactionsUseCase = GetTransactionsUseCase(repository: txRepo)
        self.deleteTransactionUseCase = DeleteTransactionUseCase(repository: txRepo)
        self.reverseTransferUseCase = ReverseTransferUseCase(repository: txRepo)
        self.calculateSplitUseCase = CalculateSplitUseCase()
        self.settleParticipantUseCase = SettleParticipantUseCase(splitRepository: splitRepo, transactionRepository: txRepo)
        self.createSplitExpenseUseCase = CreateSplitExpenseUseCase(splitRepository: splitRepo)
        self.updateSplitExpenseUseCase = UpdateSplitExpenseUseCase(splitRepository: splitRepo)
        self.deleteSplitExpenseUseCase = DeleteSplitExpenseUseCase(splitRepository: splitRepo)
        self.getSplitSummaryUseCase = GetSplitSummaryUseCase(splitRepository: splitRepo)
        self.recordParticipantPaymentUseCase = RecordParticipantPaymentUseCase(splitRepository: splitRepo)
        self.reverseParticipantPaymentUseCase = ReverseParticipantPaymentUseCase(splitRepository: splitRepo)
        self.getSplitGroupAnalyticsUseCase = GetSplitGroupAnalyticsUseCase(splitRepository: splitRepo, categoryRepository: catRepo)
        self.getSplitGroupsUseCase = GetSplitGroupsUseCase(splitRepository: splitRepo)
        self.saveSplitGroupUseCase = SaveSplitGroupUseCase(splitRepository: splitRepo)
        self.deleteSplitGroupUseCase = DeleteSplitGroupUseCase(splitRepository: splitRepo)
        self.getFinancialSummaryUseCase = GetFinancialSummaryUseCase(transactionRepository: txRepo, preferencesRepository: preferencesRepository)
        self.getBudgetProgressUseCase = GetBudgetProgressUseCase(budgetRepository: budgetRepo, transactionRepository: txRepo)
        self.saveBudgetUseCase = SaveBudgetUseCase(budgetRepository: budgetRepo)
        self.deleteBudgetUseCase = DeleteBudgetUseCase(budgetRepository: budgetRepo)
        self.getSavingsGoalsUseCase = GetSavingsGoalsUseCase(savingsGoalRepository: savingsRepo)
        self.saveSavingsGoalUseCase = SaveSavingsGoalUseCase(savingsGoalRepository: savingsRepo)
        self.deleteSavingsGoalUseCase = DeleteSavingsGoalUseCase(savingsGoalRepository: savingsRepo)
        self.setSavingsGoalArchivedUseCase = SetSavingsGoalArchivedUseCase(savingsGoalRepository: savingsRepo)
        self.recordSavingsContributionUseCase = RecordSavingsContributionUseCase(savingsGoalRepository: savingsRepo)
        self.reverseSavingsContributionUseCase = ReverseSavingsContributionUseCase(savingsGoalRepository: savingsRepo)
        self.recordSavingsWithdrawalUseCase = RecordSavingsWithdrawalUseCase(savingsGoalRepository: savingsRepo)
        self.reverseSavingsWithdrawalUseCase = ReverseSavingsWithdrawalUseCase(savingsGoalRepository: savingsRepo)
        self.getMonthlyExpenseSummaryUseCase = GetMonthlyExpenseSummaryUseCase(transactionRepository: txRepo)
        self.getCategorySpendingUseCase = GetCategorySpendingUseCase(transactionRepository: txRepo)

        let catAnalysis = GetCategoryAnalysisUseCase(transactionRepository: txRepo, categoryRepository: catRepo)
        let savingsInsights = GetSavingsInsightsUseCase(savingsGoalRepository: savingsRepo)

        self.getCategoryAnalysisUseCase = catAnalysis
        self.getSavingsInsightsUseCase = savingsInsights
        self.getSpendingTrendsUseCase = GetSpendingTrendsUseCase(transactionRepository: txRepo)
        self.getBudgetInsightsUseCase = GetBudgetInsightsUseCase(budgetRepository: budgetRepo, transactionRepository: txRepo)
        self.getInsightsSummaryUseCase = GetInsightsSummaryUseCase(
            transactionRepository: txRepo,
            categoryAnalysisUseCase: catAnalysis,
            savingsInsightsUseCase: savingsInsights
        )
        self.getFinancialObservationsUseCase = GetFinancialObservationsUseCase()

        // Statements & Export
        let pdfGen = PdfStatementGenerator()
        let csvGen = CsvStatementGenerator()
        let compileData = CompileStatementDataUseCase(
            transactionRepository: txRepo,
            categoryRepository: catRepo,
            preferencesRepository: preferencesRepository,
            savingsGoalRepository: savingsRepo,
            categoryAnalysisUseCase: catAnalysis,
            savingsInsightsUseCase: savingsInsights,
            budgetInsightsUseCase: GetBudgetInsightsUseCase(budgetRepository: budgetRepo, transactionRepository: txRepo)
        )
        let genStatement = GenerateStatementUseCase(
            compileStatementDataUseCase: compileData,
            pdfGenerator: pdfGen,
            csvGenerator: csvGen,
            statementRepository: statementRepo
        )
        let delStatement = DeleteStatementUseCase(statementRepository: statementRepo)
        let getStatements = GetStatementsUseCase(statementRepository: statementRepo)

        self.pdfStatementGenerator = pdfGen
        self.csvStatementGenerator = csvGen
        self.compileStatementDataUseCase = compileData
        self.generateStatementUseCase = genStatement
        self.deleteStatementUseCase = delStatement
        self.getStatementsUseCase = getStatements

        // Financial Tools
        self.calculateEmiUseCase = CalculateEmiUseCase()
        self.calculateSipUseCase = CalculateSipUseCase()
        self.calculateFdUseCase = CalculateFdUseCase()
        self.calculateRdUseCase = CalculateRdUseCase()
        self.calculateDiscountUseCase = CalculateDiscountUseCase()
        self.calculateGstUseCase = CalculateGstUseCase()

        // Recurring Transactions & Bill Reminders Use Cases
        self.createRecurringTransactionUseCase = CreateRecurringTransactionUseCase(
            recurringRepository: recurringRepo,
            notificationService: notifService
        )
        self.updateRecurringTransactionUseCase = UpdateRecurringTransactionUseCase(recurringRepository: recurringRepo)
        self.pauseRecurringTransactionUseCase = PauseRecurringTransactionUseCase(recurringRepository: recurringRepo)
        self.resumeRecurringTransactionUseCase = ResumeRecurringTransactionUseCase(recurringRepository: recurringRepo)
        self.cancelRecurringTransactionUseCase = CancelRecurringTransactionUseCase(recurringRepository: recurringRepo)
        self.deleteRecurringTransactionUseCase = DeleteRecurringTransactionUseCase(recurringRepository: recurringRepo)
        self.generateDueOccurrencesUseCase = GenerateDueOccurrencesUseCase(
            recurringRepository: recurringRepo,
            notificationService: notifService,
            preferencesRepository: preferencesRepository
        )
        self.getRecurringTransactionsUseCase = GetRecurringTransactionsUseCase(recurringRepository: recurringRepo)
        self.getUpcomingBillsUseCase = GetUpcomingBillsUseCase(recurringRepository: recurringRepo)
        self.markBillAsPaidUseCase = MarkBillAsPaidUseCase(
            recurringRepository: recurringRepo,
            notificationService: notifService
        )
        self.reversePaidOccurrenceUseCase = ReversePaidOccurrenceUseCase(
            recurringRepository: recurringRepo
        )
        self.skipBillOccurrenceUseCase = SkipBillOccurrenceUseCase(
            recurringRepository: recurringRepo,
            notificationService: notifService
        )
        self.snoozeBillReminderUseCase = SnoozeBillReminderUseCase(
            recurringRepository: recurringRepo,
            notificationService: notifService
        )
        self.getSubscriptionSummaryUseCase = GetSubscriptionSummaryUseCase(recurringRepository: recurringRepo)

        // Phase 9: Security, Privacy & Backup
        let keychain = KeychainService.shared
        let crypto = BackupCryptoEngine.shared
        let backup = BackupService(
            database: database,
            preferencesRepository: preferencesRepository,
            cryptoEngine: crypto,
            notificationService: notifService
        )
        let appLock = AppLockService(preferencesRepository: preferencesRepository)

        self.keychainService = keychain
        self.backupCryptoEngine = crypto
        self.backupService = backup
        self.appLockService = appLock
        self.createBackupUseCase = CreateBackupUseCase(backupService: backup)
        self.validateBackupUseCase = ValidateBackupUseCase(backupService: backup)
        self.restoreBackupUseCase = RestoreBackupUseCase(
            backupService: backup,
            generateDueOccurrencesUseCase: self.generateDueOccurrencesUseCase
        )
        self.deleteAllFinancialDataUseCase = DeleteAllFinancialDataUseCase(
            backupService: backup,
            keychainService: keychain
        )

        // Google Drive Cloud Backup
        let googleAuth = GoogleAuthService.shared
        self.googleAuthService = googleAuth
        self.googleDriveBackupService = GoogleDriveBackupService(
            authService: googleAuth,
            driveRestService: GoogleDriveRestService(),
            backupService: backup,
            restoreBackupUseCase: self.restoreBackupUseCase,
            preferencesRepository: preferencesRepository
        )

        // Phase 11: On-Device Receipt OCR Scanning
        let ocrService = ReceiptOCRService.shared
        let rStorage = ReceiptStorageService.shared
        self.receiptOCRService = ocrService
        self.receiptStorageService = rStorage
        self.processReceiptImageUseCase = ProcessReceiptImageUseCase(
            receiptOCRService: ocrService,
            receiptStorageService: rStorage,
            preferencesRepository: preferencesRepository,
            categoryRepository: catRepo
        )

        // Phase 12: Multi-Currency & Travel Wallets
        let exRateRepo = GRDBExchangeRateRepository(database: database)
        let walletRepo = GRDBTravelWalletRepository(database: database)

        self.exchangeRateRepository = exRateRepo
        self.travelWalletRepository = walletRepo

        self.getExchangeRatesUseCase = GetExchangeRatesUseCase(
            exchangeRateRepository: exRateRepo,
            preferencesRepository: preferencesRepository
        )
        self.saveExchangeRateUseCase = SaveExchangeRateUseCase(
            exchangeRateRepository: exRateRepo
        )
        self.changePrimaryCurrencyUseCase = ChangePrimaryCurrencyUseCase(
            transactionRepository: txRepo,
            exchangeRateRepository: exRateRepo,
            preferencesRepository: preferencesRepository
        )
        self.getTravelWalletsUseCase = GetTravelWalletsUseCase(
            walletRepository: walletRepo,
            transactionRepository: txRepo,
            categoryRepository: catRepo
        )
        self.saveTravelWalletUseCase = SaveTravelWalletUseCase(
            walletRepository: walletRepo
        )
        self.deleteTravelWalletUseCase = DeleteTravelWalletUseCase(
            walletRepository: walletRepo
        )
    }

    /// Factory for production runtime with on-device SQLite database.
    public static func makeLive() -> AppContainer {
        do {
            let db = try AppDatabase.makeShared()
            return AppContainer(database: db)
        } catch {
            fatalError("Failed to initialize persistent AppDatabase: \(error)")
        }
    }

    /// Factory for tests and SwiftUI previews with an in-memory database and isolated preferences.
    public static func makeInMemory() -> AppContainer {
        do {
            let db = try AppDatabase.makeInMemory()
            let suiteName = "LeafInMemoryDefaults.\(UUID().uuidString)"
            let isolatedDefaults = UserDefaults(suiteName: suiteName) ?? .standard
            let prefsRepo = UserPreferencesRepository(defaults: isolatedDefaults)
            return AppContainer(database: db, preferencesRepository: prefsRepo)
        } catch {
            fatalError("Failed to initialize in-memory AppDatabase: \(error)")
        }
    }
}

