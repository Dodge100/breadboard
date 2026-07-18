import SwiftUI

// MARK: - Floating Macro Palette

/// A floating palette view that lists all enabled manipulators and allows
/// triggering them by clicking.  Designed to be hosted inside an NSPanel
/// (floating, always-on-top).
struct MacroPaletteView: View {
    @ObservedObject var store: RemapStore
    @State private var searchText = ""

    /// Manipulators that are enabled and have at least one configured action.
    private var paletteItems: [Manipulator] {
        let base = store.debouncedFilteredManipulators
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return base
            .filter { $0.isEnabled && $0.trigger.isValid && $0.actions.contains(where: \.isConfigured) }
            .filter { manipulator in
                guard !query.isEmpty else { return true }
                return manipulator.name.lowercased().contains(query)
                    || manipulator.trigger.displayLabel.lowercased().contains(query)
                    || manipulator.actions.contains { $0.summary.lowercased().contains(query) }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar area
            HStack(spacing: 8) {
                Image(systemName: "command")
                    .foregroundStyle(.secondary)
                Text("Macro Palette")
                    .font(.headline)
                Spacer()
                Text("\(paletteItems.count) macros")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Button {
                    store.hideMacroPalette()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Close palette")
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                TextField("Search macros…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Palette items list
            if paletteItems.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(searchText.isEmpty ? "No enabled macros" : "No matching macros")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if searchText.isEmpty {
                        Text("Enable manipulators in the editor\nto see them here.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(paletteItems) { manipulator in
                            PaletteItemRow(store: store, manipulator: manipulator)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(minWidth: 300, minHeight: 200)
    }
}

// MARK: - Palette Item Row

private struct PaletteItemRow: View {
    @ObservedObject var store: RemapStore
    let manipulator: Manipulator
    @State private var isHovering = false

    var body: some View {
        Button {
            store.executeManipulatorFromPalette(manipulator)
        } label: {
            HStack(spacing: 10) {
                // Leading icon
                Image(systemName: manipulator.trigger.keyType.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)

                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    Text(manipulator.name.isEmpty ? "Untitled" : manipulator.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        // Trigger badge
                        Text(manipulator.trigger.displayLabel)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))

                        if let firstAction = manipulator.actions.first(where: { $0.isConfigured }) {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(firstAction.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 4)

                // Tags
                if !manipulator.tags.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(manipulator.tags.sorted().prefix(2)), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Edit in Editor") {
                store.selectManipulator(manipulator.id)
                store.hideMacroPalette()
                if let mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    mainWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}
