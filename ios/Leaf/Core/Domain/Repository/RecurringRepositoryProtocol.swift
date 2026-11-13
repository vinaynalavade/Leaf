import Foundation

/// Data contract for managing persistent recurring transaction schedules,
/// calendar occurrences, upcoming bill payments, and subscription tracking.
public protocol RecurringRepositoryProtocol: Sendable {

    // MARK: - Recurring Schedule CRUD

    func getAllRecurringTransactions() async throws -> [RecurringTransaction]
    func getRecurringTransaction(id: Int64) async throws -> RecurringTransaction?
    func insertRecurringTransaction(_ item: RecurringTransaction) async throws -> Int64
    func updateRecurringTransaction(_ item: RecurringTransaction) async throws
    func deleteRecurringTransaction(id: Int64) async throws
    func setRecurringTransactionStatus(id: Int64, status: RecurringScheduleStatus) async throws

    // MARK: - Occurrence Ledger

    func getOccurrences(forRecurringId recurringId: Int64) async throws -> [RecurringTransactionOccurrence]
    func getUpcomingBills(limit: Int?) async throws -> [RecurringTransactionOccurrence]
    func getOccurrence(id: Int64) async throws -> RecurringTransactionOccurrence?
    func insertOccurrenceIfNotExists(_ occurrence: RecurringTransactionOccurrence) async throws -> Int64?
    func updateOccurrenceStatus(occurrenceId: Int64, status: BillPaymentStatus, transactionId: Int64?, paidAt: Int64?) async throws
    func snoozeOccurrence(occurrenceId: Int64, untilEpoch: Int64) async throws
    func skipOccurrence(occurrenceId: Int64) async throws

    /// Atomically creates the financial ledger transaction and updates the occurrence status to PAID.
    func markOccurrenceAsPaid(
        occurrenceId: Int64,
        paymentMethod: PaymentMethod,
        paidAt: Int64
    ) async throws -> Int64

    /// Atomically reverses a previously paid occurrence: deletes the linked transaction from the
    /// ledger, clears payment fields, and restores the occurrence to DUE/OVERDUE/UPCOMING status.
    func reversePaidOccurrence(occurrenceId: Int64) async throws

    /// Re-evaluates and standardizes status for all unsettled occurrences against the user's local calendar.
    func reconcilePendingOccurrencesStatuses(referenceDate: Date) async throws

    /// Reconciles future unpaid occurrences when a recurring schedule is edited.
    /// Returns the IDs of removed occurrences so their notifications can be cleaned up.
    func reconcileFutureOccurrences(
        forRecurringId recurringId: Int64,
        updateUpcomingDueOccurrence: Bool,
        newSchedule: RecurringTransaction
    ) async throws -> [Int64]

    /// Fetches all active occurrence IDs for a recurring schedule.
    func getOccurrenceIds(forRecurringId recurringId: Int64) async throws -> [Int64]

    // MARK: - Subscriptions

    func getAllSubscriptions() async throws -> [RecurringTransaction]
}

