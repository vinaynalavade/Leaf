import Foundation
import SwiftUI

/// State coordinator for the Financial Tools landing dashboard.
@Observable
public final class ToolsLandingViewModel {

    public var selectedCategory: FinancialToolCategory = .all
    public var searchQuery: String = ""
    public var recentToolTypes: [FinancialToolType] = []
    public var activeTool: FinancialToolType? = nil

    private let recentToolsKey = "leaf_recent_financial_tools"

    public init() {
        loadRecents()
    }

    public var filteredTools: [FinancialToolType] {
        FinancialToolType.allCases.filter { tool in
            let matchesCategory = (selectedCategory == .all || tool.category == selectedCategory)
            let matchesSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                tool.title.localizedCaseInsensitiveContains(searchQuery) ||
                tool.subtitle.localizedCaseInsensitiveContains(searchQuery)
            return matchesCategory && matchesSearch
        }
    }

    public func selectTool(_ tool: FinancialToolType) {
        recordRecent(tool)
        self.activeTool = tool
    }

    private func recordRecent(_ tool: FinancialToolType) {
        var list = recentToolTypes.filter { $0 != tool }
        list.insert(tool, at: 0)
        if list.count > 3 {
            list = Array(list.prefix(3))
        }
        self.recentToolTypes = list
        let rawList = list.map { $0.rawValue }
        UserDefaults.standard.set(rawList, forKey: recentToolsKey)
    }

    private func loadRecents() {
        if let rawList = UserDefaults.standard.stringArray(forKey: recentToolsKey) {
            self.recentToolTypes = rawList.compactMap { FinancialToolType(rawValue: $0) }
        }
    }
}

