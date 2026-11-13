import Foundation
import GRDB

public struct SeedCategoryData: Sendable {
    public let name: String
    public let iconName: String
    public let colorHex: String
    public let type: String
}

public enum CategorySeeds {

    public static let defaultCategories: [SeedCategoryData] = [
        // 12 Expense Categories
        SeedCategoryData(name: "Food & Dining", iconName: "restaurant", colorHex: "#EF4444", type: "EXPENSE"),
        SeedCategoryData(name: "Transportation", iconName: "directions_car", colorHex: "#F59E0B", type: "EXPENSE"),
        SeedCategoryData(name: "Shopping", iconName: "shopping_bag", colorHex: "#8B5CF6", type: "EXPENSE"),
        SeedCategoryData(name: "Bills & Utilities", iconName: "receipt_long", colorHex: "#3B82F6", type: "EXPENSE"),
        SeedCategoryData(name: "Entertainment", iconName: "movie", colorHex: "#EC4899", type: "EXPENSE"),
        SeedCategoryData(name: "Health & Medical", iconName: "medical_services", colorHex: "#10B981", type: "EXPENSE"),
        SeedCategoryData(name: "Education", iconName: "school", colorHex: "#6366F1", type: "EXPENSE"),
        SeedCategoryData(name: "Personal Care", iconName: "spa", colorHex: "#14B8A6", type: "EXPENSE"),
        SeedCategoryData(name: "Housing & Rent", iconName: "home", colorHex: "#F97316", type: "EXPENSE"),
        SeedCategoryData(name: "EMI & Loans", iconName: "account_balance", colorHex: "#DC2626", type: "EXPENSE"),
        SeedCategoryData(name: "Subscriptions", iconName: "subscriptions", colorHex: "#7C3AED", type: "EXPENSE"),
        SeedCategoryData(name: "Other Expense", iconName: "more_horiz", colorHex: "#64748B", type: "EXPENSE"),

        // 8 Income Categories
        SeedCategoryData(name: "Salary", iconName: "payments", colorHex: "#10B981", type: "INCOME"),
        SeedCategoryData(name: "Freelance & Consulting", iconName: "work", colorHex: "#3B82F6", type: "INCOME"),
        SeedCategoryData(name: "Investments & Dividends", iconName: "trending_up", colorHex: "#8B5CF6", type: "INCOME"),
        SeedCategoryData(name: "Rental Income", iconName: "real_estate_agent", colorHex: "#F59E0B", type: "INCOME"),
        SeedCategoryData(name: "Business Revenue", iconName: "storefront", colorHex: "#06B6D4", type: "INCOME"),
        SeedCategoryData(name: "Gifts & Grants", iconName: "card_giftcard", colorHex: "#EC4899", type: "INCOME"),
        SeedCategoryData(name: "Refunds & Cashbacks", iconName: "replay", colorHex: "#14B8A6", type: "INCOME"),
        SeedCategoryData(name: "Other Income", iconName: "attach_money", colorHex: "#64748B", type: "INCOME")
    ]

    public static func seedDefaultCategories(_ db: Database) throws {
        for cat in defaultCategories {
            try db.execute(
                sql: "INSERT INTO categories (name, icon_name, color_hex, type, is_default) VALUES (?, ?, ?, ?, 1)",
                arguments: [cat.name, cat.iconName, cat.colorHex, cat.type]
            )
        }
    }
}

