import SwiftUI

public struct MainTabView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
            .tag(0)

            NavigationStack {
                ExpensesView()
            }
            .tabItem {
                Label("Expenses", systemImage: "creditcard.fill")
            }
            .tag(1)

            NavigationStack {
                SplitLandingView()
            }
            .tabItem {
                Label("Split & Collect", systemImage: "person.2.fill")
            }
            .tag(2)

            NavigationStack {
                PlanningView()
            }
            .tabItem {
                Label("Planning", systemImage: "target")
            }
            .tag(3)

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }
            .tag(4)
        }
        .tint(LeafTheme.accent(for: colorScheme))
        .onOpenURL { url in
            switch url.host {
            case "dashboard":
                selectedTab = 0
            case "add-expense", "expenses":
                selectedTab = 1
            case "split":
                selectedTab = 2
            case "planning":
                selectedTab = 3
            case "insights":
                selectedTab = 4
            default:
                break
            }
        }
    }
}

