import Foundation
import GRDB

/// The SQLite database manager for Leaf, built on GRDB.swift.
/// Provides thread-safe synchronous and asynchronous database access with foreign key constraints enabled.
public final class AppDatabase: Sendable {

    public let writer: any DatabaseWriter
    public var reader: any DatabaseReader { writer }

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try DatabaseMigrations.migrator.migrate(writer)
    }

    /// Creates an in-memory SQLite database instance populated with all migrations and seeds.
    /// Ideal for fast, isolated unit and integration testing.
    public static func makeInMemory() throws -> AppDatabase {
        var config = Configuration()
        config.foreignKeysEnabled = true
        #if DEBUG
        config.label = "Leaf.InMemoryDatabase"
        #endif
        let queue = try DatabaseQueue(configuration: config)
        return try AppDatabase(queue)
    }

    /// Creates the persistent on-device SQLite database stored in the Application Support directory.
    public static func makeShared() throws -> AppDatabase {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbFolderURL = appSupportURL.appendingPathComponent("LeafDatabase", isDirectory: true)
        try fileManager.createDirectory(at: dbFolderURL, withIntermediateDirectories: true)

        let dbURL = dbFolderURL.appendingPathComponent("expense_tracker.sqlite")

        var config = Configuration()
        config.foreignKeysEnabled = true
        config.qos = .userInitiated
        #if DEBUG
        config.label = "Leaf.SharedDatabase"
        #endif

        let pool = try DatabasePool(path: dbURL.path, configuration: config)

        // Enforce iOS hardware-level complete file protection across SQLite and WAL journal files
        enforceFileProtection(at: dbURL)

        return try AppDatabase(pool)
    }

    /// Enforces iOS hardware-level complete file protection across SQLite database, WAL, and SHM files.
    public static func enforceFileProtection(at dbURL: URL) {
        let fileManager = FileManager.default
        let folder = dbURL.deletingLastPathComponent().path
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: folder)

        let paths = [
            dbURL.path,
            dbURL.path + "-wal",
            dbURL.path + "-shm"
        ]
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: path)
            }
        }
    }
}

