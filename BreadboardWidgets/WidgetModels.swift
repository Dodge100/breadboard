import Foundation
import WidgetKit

// MARK: - Shared Data (via App Group)

/// Shared data accessible from both the main app and the widget extension.
struct BreadboardWidgetData: Codable, Equatable {
    /// Total number of manipulators
    var manipulatorCount: Int = 0
    /// Number of enabled manipulators
    var enabledManipulatorCount: Int = 0
    /// Active profile name
    var activeProfileName: String = "Default"
    /// Active profile icon
    var activeProfileIcon: String = "person"
    /// Whether remaps are currently active
    var remapsActive: Bool = false
    /// Remap status text
    var statusText: String = "No active remaps"
    /// System CPU usage (0-100)
    var cpuUsage: Double = 0
    /// System memory usage (0-100)
    var memoryUsage: Double = 0
    /// System uptime in seconds
    var uptime: TimeInterval = 0
    /// Number of running processes
    var processCount: Int = 0
    /// App variables (key-value pairs)
    var variables: [String: String] = [:]
    /// Timestamp of last update
    var lastUpdated: Date = Date()

    static let appGroupID = "group.com.dodge1.breadboard"

    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Save current data to shared UserDefaults.
    func save() {
        guard let defaults = Self.sharedUserDefaults,
              let encoded = try? JSONEncoder().encode(self) else { return }
        defaults.set(encoded, forKey: "widgetData")
    }

    /// Load from shared UserDefaults.
    static func load() -> BreadboardWidgetData {
        guard let defaults = Self.sharedUserDefaults,
              let data = defaults.data(forKey: "widgetData"),
              let decoded = try? JSONDecoder().decode(BreadboardWidgetData.self, from: data)
        else {
            return BreadboardWidgetData()
        }
        return decoded
    }
}

// MARK: - Timeline Entries

struct ActiveRemapsEntry: TimelineEntry {
    let date: Date
    let data: BreadboardWidgetData
    let relevance: TimelineEntryRelevance?
}

struct QuickActionsEntry: TimelineEntry {
    let date: Date
    let data: BreadboardWidgetData
    let relevance: TimelineEntryRelevance?
}

struct SystemMonitorEntry: TimelineEntry {
    let date: Date
    let data: BreadboardWidgetData
    let relevance: TimelineEntryRelevance?
}

struct VariableMonitorEntry: TimelineEntry {
    let date: Date
    let data: BreadboardWidgetData
    let relevance: TimelineEntryRelevance?
}

// MARK: - Timeline Providers

struct ActiveRemapsProvider: TimelineProvider {
    typealias Entry = ActiveRemapsEntry

    func placeholder(in context: Context) -> ActiveRemapsEntry {
        ActiveRemapsEntry(date: Date(), data: BreadboardWidgetData(), relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ActiveRemapsEntry) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = ActiveRemapsEntry(date: Date(), data: data, relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActiveRemapsEntry>) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = ActiveRemapsEntry(date: Date(), data: data, relevance: nil)
        // Refresh every 15 minutes, but also rely on the app pushing updates
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickActionsProvider: TimelineProvider {
    typealias Entry = QuickActionsEntry

    func placeholder(in context: Context) -> QuickActionsEntry {
        QuickActionsEntry(date: Date(), data: BreadboardWidgetData(), relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionsEntry) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = QuickActionsEntry(date: Date(), data: data, relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsEntry>) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = QuickActionsEntry(date: Date(), data: data, relevance: nil)
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SystemMonitorProvider: TimelineProvider {
    typealias Entry = SystemMonitorEntry

    func placeholder(in context: Context) -> SystemMonitorEntry {
        SystemMonitorEntry(date: Date(), data: BreadboardWidgetData(), relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemMonitorEntry) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = SystemMonitorEntry(date: Date(), data: data, relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemMonitorEntry>) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = SystemMonitorEntry(date: Date(), data: data, relevance: nil)
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct VariableMonitorProvider: TimelineProvider {
    typealias Entry = VariableMonitorEntry

    func placeholder(in context: Context) -> VariableMonitorEntry {
        VariableMonitorEntry(date: Date(), data: BreadboardWidgetData(), relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (VariableMonitorEntry) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = VariableMonitorEntry(date: Date(), data: data, relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VariableMonitorEntry>) -> Void) {
        let data = BreadboardWidgetData.load()
        let entry = VariableMonitorEntry(date: Date(), data: data, relevance: nil)
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
