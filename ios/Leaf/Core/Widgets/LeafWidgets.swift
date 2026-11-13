import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Timeline Entry & Provider

public struct LeafWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetFinancialSnapshot

    public init(date: Date = Date(), snapshot: WidgetFinancialSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct LeafWidgetTimelineProvider: TimelineProvider {
    public typealias Entry = LeafWidgetEntry

    public init() {}

    public func placeholder(in context: Context) -> LeafWidgetEntry {
        LeafWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LeafWidgetEntry) -> Void) {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        completion(LeafWidgetEntry(date: Date(), snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LeafWidgetEntry>) -> Void) {
        let snapshot = WidgetDataManager.shared.loadSnapshot()
        let currentEntry = LeafWidgetEntry(date: Date(), snapshot: snapshot)

        // Refresh automatically every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views Routing

public struct LeafWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    public let entry: LeafWidgetEntry

    public init(entry: LeafWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            LeafSmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            LeafMediumWidgetView(snapshot: entry.snapshot)
        case .systemLarge:
            LeafLargeWidgetView(snapshot: entry.snapshot)
        default:
            LeafMediumWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Widget Configuration

public struct LeafQuickSummaryWidget: Widget {
    public let kind: String = "LeafQuickSummaryWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LeafWidgetTimelineProvider()) { entry in
            LeafWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Leaf Financial Snapshot")
        .description("View your total balance, monthly spending, and budget progress directly on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
public struct LeafWidgetsBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        LeafQuickSummaryWidget()
    }
}
