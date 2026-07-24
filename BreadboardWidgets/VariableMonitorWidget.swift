import WidgetKit
import SwiftUI

// MARK: - Variable Monitor Widget

struct VariableMonitorWidget: Widget {
    let kind: String = "com.dodge1.breadboard.variable-monitor"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VariableMonitorProvider()) { entry in
            VariableMonitorWidgetView(entry: entry)
        }
        .configurationDisplayName("Variable Monitor")
        .description("Monitor Breadboard variables at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemExtraLarge])
    }
}

// MARK: - Widget View

struct VariableMonitorWidgetView: View {
    var entry: VariableMonitorEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemExtraLarge:
                extraLargeView
            default:
                mediumView
            }
        }
        .containerBackground(Color(nsColor: .windowBackgroundColor).opacity(0.85), for: .widget)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Variables", systemImage: "variable")
                .font(.headline)
                .foregroundStyle(.primary)

            if entry.data.variables.isEmpty {
                Spacer()
                Text("No variables")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                let topVars = entry.data.variables.prefix(3)
                ForEach(topVars.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
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

                if entry.data.variables.count > 3 {
                    Text("+\(entry.data.variables.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Variables", systemImage: "variable")
                .font(.headline)
                .foregroundStyle(.primary)

            if entry.data.variables.isEmpty {
                Spacer()
                Text("No variables set. Use Set Variable actions to create them.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                let topVars = entry.data.variables.prefix(6)
                ForEach(topVars.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
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
                            .monospacedDigit()
                    }
                    .padding(.vertical, 1)
                }

                if entry.data.variables.count > 6 {
                    Text("+\(entry.data.variables.count - 6) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var extraLargeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Variables", systemImage: "variable")
                .font(.headline)
                .foregroundStyle(.primary)

            if entry.data.variables.isEmpty {
                Spacer()
                Text("No variables set. Use Set Variable actions to create them.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                let columns = [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .trailing)
                ]

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(entry.data.variables.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            Text(key)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Text(value)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    VariableMonitorWidget()
} timeline: {
    VariableMonitorEntry(date: Date(), data: BreadboardWidgetData(
        variables: [
            "counter": "42",
            "lastApp": "Safari",
            "batteryLevel": "85",
            "ipAddress": "192.168.1.5"
        ]
    ), relevance: nil)
}
