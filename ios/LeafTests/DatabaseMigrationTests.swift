import XCTest
import GRDB
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class DatabaseMigrationTests: XCTestCase {

    func testDatabaseMigrationsExecuteCleanly() throws {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(configuration: config)

        // Run migrations
        try DatabaseMigrations.migrator.migrate(queue)

        // Verify all 10 tables exist
        try queue.read { db in
            let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'table'")
            let expectedTables = [
                "categories",
                "transactions",
                "recurring_transactions",
                "split_expenses",
                "split_participants",
                "budgets",
                "savings_goals",
                "savings_goal_contributions",
                "split_groups",
                "reminders"
            ]

            for expected in expectedTables {
                XCTAssertTrue(tables.contains(expected), "Missing expected table: \(expected)")
            }
        }
    }

    func testDefaultCategoriesAreSeeded() throws {
        let appDb = try AppDatabase.makeInMemory()

        try appDb.writer.read { db in
            let categoryCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories") ?? 0
            XCTAssertEqual(categoryCount, 20)

            let defaultCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories WHERE is_default = 1") ?? 0
            XCTAssertEqual(defaultCount, 20)

            let expenseCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories WHERE type = 'EXPENSE'") ?? 0
            XCTAssertEqual(expenseCount, 12)

            let incomeCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories WHERE type = 'INCOME'") ?? 0
            XCTAssertEqual(incomeCount, 8)
        }
    }

    func testForeignKeyConstraintsEnforced() throws {
        let appDb = try AppDatabase.makeInMemory()

        // Inserting a transaction with invalid category ID must fail due to foreign key constraint
        XCTAssertThrowsError(
            try appDb.writer.write { db in
                var tx = TransactionRecord(
                    amountSubunits: 1000,
                    type: "EXPENSE",
                    categoryId: 99999 // Non-existent category
                )
                try tx.insert(db)
            }
        )
    }
}

