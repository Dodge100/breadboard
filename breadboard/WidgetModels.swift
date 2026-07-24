import AppKit
import Combine
import Foundation
import WidgetKit

// MARK: - Shared Data (duplicated in widget extension for App Group sharing)

/// Shared data accessible from both the main app and the widget extension.
struct BreadboardWidgetData: Codable, Equatable {
    var manipulatorCount: Int = 0
    var enabledManipulatorCount: Int = 0
    var activeProfileName: String = "Default"
    var activeProfileIcon: String = "person"
    var remapsActive: Bool = false
    var statusText: String = "No active remaps"
    var cpuUsage: Double = 0
    var memoryUsage: Double = 0
    var uptime: TimeInterval = 0
    var processCount: Int = 0
    var variables: [String: String] = [:]
    var lastUpdated: Date = Date()

    static let appGroupID = "group.com.dodge1.breadboard"

    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    func save() {
        guard let defaults = Self.sharedUserDefaults,
              let encoded = try? JSONEncoder().encode(self) else { return }
        defaults.set(encoded, forKey: "widgetData")
    }

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

// MARK: - Widget Kind

/// The types of widgets the app provides to Notification Center.
enum AppWidgetKind: String, CaseIterable, Identifiable, Codable {
    case activeRemaps = "Active Remaps"
    case quickActions = "Quick Actions"
    case systemMonitor = "System Monitor"
    case variableMonitor = "Variable Monitor"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .activeRemaps: return "keyboard"
        case .quickActions: return "bolt.fill"
        case .systemMonitor: return "chart.pie"
        case .variableMonitor: return "variable"
        }
    }

    var description: String {
        switch self {
        case .activeRemaps: return "Shows how many keyboard remaps are currently active."
        case .quickActions: return "Quick access to toggle remaps and switch profiles."
        case .systemMonitor: return "CPU, memory, and process monitoring at a glance."
        case .variableMonitor: return "Monitor Breadboard variables at a glance."
        }
    }

    var families: [String] {
        switch self {
        case .activeRemaps: return ["Small", "Medium"]
        case .quickActions: return ["Medium", "Extra Large"]
        case .systemMonitor: return ["Small", "Medium"]
        case .variableMonitor: return ["Small", "Medium", "Extra Large"]
        }
    }

    var widgetKind: String {
        switch self {
        case .activeRemaps: return "com.dodge1.breadboard.active-remaps"
        case .quickActions: return "com.dodge1.breadboard.quick-actions"
        case .systemMonitor: return "com.dodge1.breadboard.system-monitor"
        case .variableMonitor: return "com.dodge1.breadboard.variable-monitor"
        }
    }
}

// MARK: - Widget Manager

/// Manages the app's WidgetKit widgets — used from the Widgets dashboard.
@MainActor
final class WidgetManager: ObservableObject {
    static let shared = WidgetManager()

    /// All available widget types.
    let availableWidgets: [AppWidgetKind] = AppWidgetKind.allCases

    /// The last time the shared data was updated.
    @Published var lastDataUpdate: Date = Date()

    private init() {}

    /// Reload all widget timelines from the app.
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        lastDataUpdate = Date()
    }

    /// Reload a specific widget kind.
    func reloadWidget(kind: AppWidgetKind) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind.widgetKind)
    }

    /// Open Notification Center / widget gallery.
    func openWidgetGallery() {
        NSApp.activate(ignoringOtherApps: true)
    }
}
