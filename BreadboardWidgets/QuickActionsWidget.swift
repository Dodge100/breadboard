import WidgetKit
import SwiftUI

// MARK: - Quick Actions Widget

struct QuickActionsWidget: Widget {
    let kind: String = "com.dodge1.breadboard.quick-actions"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quick access to toggle remaps and switch profiles.")
        .supportedFamilies([.systemMedium, .systemExtraLarge])
    }
}

// MARK: - Widget View

struct QuickActionsWidgetView: View {
    var entry: QuickActionsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemExtraLarge:
                extraLargeView
            default:
                mediumView
            }
        }
        .containerBackground(Color(nsColor: .windowBackgroundColor).opacity(0.85), for: .widget)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                // Toggle Remaps
                Link(destination: URL(string: "breadboard://toggle-remaps")!) {
                    VStack(spacing: 6) {
                        Image(systemName: entry.data.remapsActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(entry.data.remapsActive ? .orange : .green)
                        Text(entry.data.remapsActive ? "Pause" : "Resume")
                            .font(.caption2)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(.tertiary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                // Open Breadboard
                Link(destination: URL(string: "breadboard://open")!) {
                    VStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Text("Open App")
                            .font(.caption2)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(.tertiary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                // Profile info
                VStack(spacing: 6) {
                    Image(systemName: entry.data.activeProfileIcon)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(entry.data.activeProfileName)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(.tertiary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var extraLargeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ActionTile(icon: entry.data.remapsActive ? "pause.circle.fill" : "play.circle.fill",
                          color: entry.data.remapsActive ? .orange : .green,
                          label: entry.data.remapsActive ? "Pause" : "Resume",
                          url: "breadboard://toggle-remaps")

                ActionTile(icon: "keyboard", color: .accentColor, label: "Open App", url: "breadboard://open")

                ActionTile(icon: "arrow.triangle.2.circlepath", color: .blue, label: "Reload", url: "breadboard://reload")

                ActionTile(icon: entry.data.activeProfileIcon, color: .secondary, label: entry.data.activeProfileName, url: "breadboard://open")
            }

            HStack {
                Text(entry.data.statusText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Spacer()
                Text(entry.data.lastUpdated, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Action Tile

private struct ActionTile: View {
    let icon: String
    let color: Color
    let label: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.tertiary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    QuickActionsWidget()
} timeline: {
    QuickActionsEntry(date: Date(), data: BreadboardWidgetData(
        activeProfileName: "Gaming",
        activeProfileIcon: "gamecontroller",
        remapsActive: true,
        statusText: "12 remaps active"
    ), relevance: nil)
}
