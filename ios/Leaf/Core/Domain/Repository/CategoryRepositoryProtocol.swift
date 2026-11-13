import Foundation

public protocol CategoryRepositoryProtocol: Sendable {
    func getAllCategories() async throws -> [Category]
    func getCategory(id: Int64) async throws -> Category?
    func insertCategory(_ category: Category) async throws -> Int64
    func updateCategory(_ category: Category) async throws
    func deleteCategory(id: Int64) async throws
}

