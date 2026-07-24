import SwiftUI
import WidgetKit

// MARK: - Widgets Dashboard

struct WidgetsView: View {
    @ObservedObject var store: RemapStore
    @StateObject private var widgetManager = WidgetManager.shared
    @State private var selectedWidget: AppWidgetKind? = .activeRemaps

    var body: some View {
        NavigationSplitView {
            WidgetsSidebar(selectedWidget: $selectedWidget)
                .navigationTitle("Widgets")
        } detail: {
            if let kind = selectedWidget {
                WidgetDetailView(kind: kind, store: store, widgetManager: widgetManager)
                    .frame(minWidth: 480)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    widgetManager.reloadAllWidgets()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload all widget timelines")

                ProfileSwitcherButton(store: store)
            }
        }
        .onAppear {
            pushWidgetData(store: store)
        }
        .onChange(of: store.manipulators.count) { _ in pushWidgetData(store: store) }
        .onChange(of: store.activeProfileID) { _ in pushWidgetData(store: store) }
        .onChange(of: store.remapIsActive) { _ in pushWidgetData(store: store) }
    }

    /// Push current app state to the shared App Group container for widgets.
    private func pushWidgetData(store: RemapStore) {
        var data = BreadboardWidgetData()
        data.manipulatorCount = store.manipulators.count
        data.enabledManipulatorCount = store.manipulators.filter(\.isEnabled).count
        data.activeProfileName = store.activeProfile?.name ?? "Default"
        data.activeProfileIcon = store.activeProfile?.icon ?? "person"
        data.remapsActive = store.remapIsActive
        data.statusText = store.remapStatusText
        data.variables = store.engine.variables
        data.save()
        widgetManager.reloadAllWidgets()
    }
}

// MARK: - Sidebar

private struct WidgetsSidebar: View {
    @Binding var selectedWidget: AppWidgetKind?

    var body: some View {
        List(selection: $selectedWidget) {
            Section("Available Widgets") {
                ForEach(AppWidgetKind.allCases) { kind in
                    WidgetSidebarRow(kind: kind)
                        .tag(kind)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 240)
    }
}

// MARK: - Sidebar Row

private struct WidgetSidebarRow: View {
    let kind: AppWidgetKind

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: kind.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.rawValue)
                    .font(.body)
                Text(kind.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Widget Detail View

private struct WidgetDetailView: View {
    let kind: AppWidgetKind
    @ObservedObject var store: RemapStore
    @ObservedObject var widgetManager: WidgetManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                Divider()

                // Live preview card
                previewSection

                Divider()

                // Sizes
                sizesSection

                Divider()

                // Info
                infoSection
            }
            .padding(24)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.rawValue)
                    .font(.largeTitle.weight(.bold))

                Text(kind.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Button("Add to Notification Center") {
                    // Guide the user to add the widget
                    let alert = NSAlert()
                    alert.messageText = "Add Widget to Notification Center"
                    alert.informativeText = """
                    1. Open Notification Center (click the date in the menu bar).
                    2. Scroll to the bottom and click "Edit Widgets".
                    3. Find "Breadboard" in the widget list.
                    4. Click the "\(kind.rawValue)" widget to add it.
                    """
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Open Notification Center")
                    alert.addButton(withTitle: "OK")

                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        // macOS doesn't have a public API for this,
                        // but we can try to open the widget gallery URL
                        if let url = URL(string: "breadboard://widget-gallery") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                .controlSize(.large)

                Text("Or right-click on the desktop and select \"Edit Widgets\".")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Preview", systemImage: "eye")
                .font(.title3.weight(.semibold))

            HStack(spacing: 24) {
                WidgetPreviewCard(kind: kind, size: .small)
                WidgetPreviewCard(kind: kind, size: .medium)
                if kind == .variableMonitor {
                    WidgetPreviewCard(kind: kind, size: .extraLarge)
                }
            }
        }
    }

    // MARK: - Sizes

    private var sizesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Available Sizes", systemImage: "rectangle.split.triangles")
                .font(.title3.weight(.semibold))

            HStack(spacing: 16) {
                ForEach(kind.families, id: \.self) { size in
                    HStack(spacing: 6) {
                        Image(systemName: sizeIcon(for: size))
                            .foregroundStyle(.secondary)
                        Text(size)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private func sizeIcon(for size: String) -> String {
        switch size {
        case "Small": return "rectangle"
        case "Medium": return "rectangle.split.2x1"
        case "Extra Large": return "rectangle.split.3x1"
        default: return "rectangle"
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Widget Data", systemImage: "info.circle")
                .font(.title3.weight(.semibold))

            VStack(spacing: 6) {
                DataRow(label: "Widget Kind ID", value: kind.widgetKind)
                DataRow(label: "Last Data Update", value: widgetManager.lastDataUpdate.formatted(date: .abbreviated, time: .standard))
                DataRow(label: "Remaps Active", value: store.remapIsActive ? "Yes" : "No")
                DataRow(label: "Active Profile", value: store.activeProfile?.name ?? "None")
                DataRow(label: "Total Remaps", value: "\(store.manipulators.count)")
                DataRow(label: "Enabled Remaps", value: "\(store.manipulators.filter(\.isEnabled).count)")
                DataRow(label: "Variables Tracked", value: "\(store.engine.variables.count)")
            }
            .padding()
            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("Reload Widget Now") {
                    widgetManager.reloadWidget(kind: kind)
                }
                .controlSize(.small)

                Button("Reload All Widgets") {
                    widgetManager.reloadAllWidgets()
                }
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Data Row

private struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Widget Preview Card

private struct WidgetPreviewCard: View {
    let kind: AppWidgetKind
    let size: WidgetPreviewSize

    enum WidgetPreviewSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case extraLarge = "Extra Large"

        var widgetFamily: WidgetFamily {
            switch self {
            case .small: return .systemSmall
            case .medium: return .systemMedium
            case .extraLarge: return .systemExtraLarge
            }
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(size.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            previewContent
                .frame(width: previewWidth, height: previewHeight)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.widgetBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.quaternary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch kind {
        case .activeRemaps:
            ActiveRemapsPreview(size: size)
        case .quickActions:
            QuickActionsPreview(size: size)
        case .systemMonitor:
            SystemMonitorPreview(size: size)
        case .variableMonitor:
            VariableMonitorPreview(size: size)
        }
    }

    private var previewWidth: CGFloat {
        switch size {
        case .small: return 158
        case .medium: return 340
        case .extraLarge: return 340
        }
    }

    private var previewHeight: CGFloat {
        switch size {
        case .small: return 158
        case .medium: return 158
        case .extraLarge: return 340
        }
    }
}

// MARK: - Widget Previews

private struct ActiveRemapsPreview: View {
    let size: WidgetPreviewCard.WidgetPreviewSize

    var body: some View {
        switch size {
        case .small:
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.tertiary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "keyboard")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                Text("8")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Remaps", systemImage: "keyboard")
                        .font(.headline)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("8")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("/ 12")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("Active").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "gamecontroller").font(.caption)
                        Text("Gaming").font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tertiary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                    Text("8 remaps active")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct QuickActionsPreview: View {
    let size: WidgetPreviewCard.WidgetPreviewSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)

            HStack(spacing: 12) {
                actionTile(icon: "pause.circle.fill", color: .orange, label: "Pause")
                actionTile(icon: "keyboard", color: .accentColor, label: "Open App")
                actionTile(icon: "gamecontroller", color: .secondary, label: "Gaming")
            }
        }
        .padding(.horizontal, 16)
    }

    private func actionTile(icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.tertiary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct SystemMonitorPreview: View {
    let size: WidgetPreviewCard.WidgetPreviewSize

    var body: some View {
        switch size {
        case .small:
            VStack(spacing: 10) {
                Gauge(value: 0.45) {
                    Label("CPU", systemImage: "cpu").font(.caption2)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.orange)
                .scaleEffect(0.85)

                VStack(spacing: 2) {
                    HStack {
                        Text("RAM").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("62%").font(.caption2).foregroundStyle(.secondary)
                    }
                    ProgressView(value: 0.62).tint(.orange)
                }
            }
            .padding(.horizontal, 16)
        default:
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Gauge(value: 0.45) {
                        Label("CPU", systemImage: "cpu")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.orange)
                    Text("45%").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }

                Divider().frame(height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Memory", systemImage: "memorychip").font(.subheadline).foregroundStyle(.secondary)
                    ProgressView(value: 0.62).tint(.orange)
                    Text("62% used").font(.caption).foregroundStyle(.tertiary)
                    Spacer()
                    HStack {
                        Label("187", systemImage: "terminal").font(.caption2).foregroundStyle(.tertiary)
                        Spacer()
                        Text("3d 5h").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct VariableMonitorPreview: View {
    let size: WidgetPreviewCard.WidgetPreviewSize

    private var sampleVars: [(String, String)] {
        [("counter", "42"), ("lastApp", "Safari"), ("batteryLevel", "85%"), ("ipAddress", "192.168.1.5")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Variables", systemImage: "variable")
                .font(.headline)

            ForEach(sampleVars.prefix(size == .small ? 3 : 4), id: \.0) { key, value in
                HStack {
                    Text(key)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(value)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            if size == .small {
                Text("+1 more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Widget Background Color (matches macOS Notification Center)

private extension ShapeStyle where Self == Color {
    static var widgetBackground: Color {
        Color(nsColor: .windowBackgroundColor).opacity(0.85)
    }
}

// MARK: - Preview

#Preview {
    WidgetsView(store: RemapStore())
}
