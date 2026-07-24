import WidgetKit
import SwiftUI

// MARK: - System Monitor Widget

struct SystemMonitorWidget: Widget {
    let kind: String = "com.dodge1.breadboard.system-monitor"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SystemMonitorProvider()) { entry in
            SystemMonitorWidgetView(entry: entry)
        }
        .configurationDisplayName("System Monitor")
        .description("CPU, memory, and process monitoring at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct SystemMonitorWidgetView: View {
    var entry: SystemMonitorEntry
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
        VStack(spacing: 10) {
            // CPU gauge
            Gauge(value: entry.data.cpuUsage / 100) {
                Label("CPU", systemImage: "cpu")
                    .font(.caption2)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(entry.data.cpuUsage > 80 ? .red : entry.data.cpuUsage > 50 ? .orange : .green)
            .scaleEffect(0.85)

            // Memory bar
            VStack(spacing: 2) {
                HStack {
                    Text("RAM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(entry.data.memoryUsage))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: entry.data.memoryUsage / 100)
                    .tint(entry.data.memoryUsage > 80 ? .red : entry.data.memoryUsage > 50 ? .orange : .green)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // CPU gauge
            VStack(spacing: 4) {
                Gauge(value: entry.data.cpuUsage / 100) {
                    Label("CPU", systemImage: "cpu")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(entry.data.cpuUsage > 80 ? .red : entry.data.cpuUsage > 50 ? .orange : .green)

                Text("\(Int(entry.data.cpuUsage))%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 80)

            // Memory
            VStack(alignment: .leading, spacing: 8) {
                Label("Memory", systemImage: "memorychip")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: entry.data.memoryUsage / 100)
                    .tint(entry.data.memoryUsage > 80 ? .red : entry.data.memoryUsage > 50 ? .orange : .green)

                Text("\(Int(entry.data.memoryUsage))% used")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                HStack {
                    Label("\(entry.data.processCount)", systemImage: "terminal")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text(formatUptime(entry.data.uptime))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let d = Int(seconds) / 86400
        let h = Int(seconds) / 3600 % 24
        let m = Int(seconds) / 60 % 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Previews

#Preview(as: .systemMedium) {
    SystemMonitorWidget()
} timeline: {
    SystemMonitorEntry(date: Date(), data: BreadboardWidgetData(
        cpuUsage: 45,
        memoryUsage: 62,
        uptime: 86400 * 3 + 3600 * 5,
        processCount: 187
    ), relevance: nil)
}
