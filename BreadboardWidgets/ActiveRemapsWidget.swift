import WidgetKit
import SwiftUI

// MARK: - Active Remaps Widget

struct ActiveRemapsWidget: Widget {
    let kind: String = "com.dodge1.breadboard.active-remaps"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveRemapsProvider()) { entry in
            ActiveRemapsWidgetView(entry: entry)
        }
        .configurationDisplayName("Active Remaps")
        .description("Shows how many keyboard remaps are currently active.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct ActiveRemapsWidgetView: View {
    var entry: ActiveRemapsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            default:
                mediumView
            }
        }
        .containerBackground(Color(nsColor: .windowBackgroundColor).opacity(0.85), for: .widget)
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            // Icon + count
            ZStack {
                Circle()
                    .fill(.tertiary.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundStyle(entry.data.remapsActive ? .green : .secondary)
            }

            Text("\(entry.data.enabledManipulatorCount)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            Text("Active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left: overview
            VStack(alignment: .leading, spacing: 6) {
                Label("Remaps", systemImage: "keyboard")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.data.enabledManipulatorCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.data.remapsActive ? .green : .secondary)
                        .contentTransition(.numericText())

                    Text("/ \(entry.data.manipulatorCount)")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.data.remapsActive ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(entry.data.remapsActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right: profile + status
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: entry.data.activeProfileIcon)
                        .font(.caption)
                    Text(entry.data.activeProfileName)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.tertiary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

                Text(entry.data.statusText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    ActiveRemapsWidget()
} timeline: {
    ActiveRemapsEntry(date: Date(), data: BreadboardWidgetData(
        manipulatorCount: 12,
        enabledManipulatorCount: 8,
        remapsActive: true,
        statusText: "8 remaps active — All systems nominal"
    ), relevance: nil)
}
