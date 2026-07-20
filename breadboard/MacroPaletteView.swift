import SwiftUI

// MARK: - Floating Macro Palette

/// A floating palette view that lists all enabled manipulators and allows
/// triggering them by clicking.  Designed to be hosted inside an NSPanel
/// (floating, always-on-top).
struct MacroPaletteView: View {
    @ObservedObject var store: RemapStore
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

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
                    || manipulator.tags.contains { $0.lowercased().contains(query) }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Group items by first tag (or "General" if no tags).
    private var groupedItems: [(String, [Manipulator])] {
        var groups: [String: [Manipulator]] = [:]
        for item in paletteItems {
            let group = item.tags.sorted().first ?? "General"
            groups[group, default: []].append(item)
        }
        return groups
            .sorted { $0.key < $1.key }
    }

    private var shouldShowGroups: Bool {
        groupedItems.count > 1 && searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar (top)
            SearchBar(text: $searchText, isFocused: $isSearchFocused)
                .padding(.top, 8)
                .padding(.horizontal, 12)

            Divider()
                .padding(.top, 8)

            // Content
            if paletteItems.isEmpty {
                emptyState
            } else if shouldShowGroups {
                groupedContent
            } else {
                flatContent
            }
        }
        .background(.background)
        .frame(minWidth: 320, idealWidth: 360, minHeight: 280, idealHeight: 420)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "command.square")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            VStack(spacing: 4) {
                Text(searchText.isEmpty ? "No Macros Available" : "No Matching Macros")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(searchText.isEmpty
                    ? "Enable macros in the editor to see them here."
                    : "Try a different search term.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grouped Content

    private var groupedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(groupedItems, id: \.0) { group, items in
                    GroupHeader(title: group)
                    ForEach(items) { manipulator in
                        PaletteItemRow(store: store, manipulator: manipulator)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Flat Content

    private var flatContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(paletteItems) { manipulator in
                    PaletteItemRow(store: store, manipulator: manipulator)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.body)

            TextField("Search macros…", text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused(isFocused)
                .onSubmit {}

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isFocused.wrappedValue ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused.wrappedValue)
    }
}

// MARK: - Group Header

private struct GroupHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .padding(.top, 4)
    }
}

// MARK: - Palette Item Row

private struct PaletteItemRow: View {
    @ObservedObject var store: RemapStore
    let manipulator: Manipulator
    @State private var isHovering = false
    @State private var wasJustTriggered = false

    private var primaryActionSummary: String? {
        manipulator.actions.first(where: { $0.isConfigured })?.summary
    }

    var body: some View {
        Button {
            store.executeManipulatorFromPalette(manipulator)
            withAnimation(.easeOut(duration: 0.6)) {
                wasJustTriggered = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.3)) {
                    wasJustTriggered = false
                }
            }
        } label: {
            HStack(spacing: 10) {
                // Trigger key icon
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.accentColor.opacity(isHovering ? 0.18 : 0.10))
                    Text(triggerKeyLabel)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 28, height: 22)

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(manipulator.name.isEmpty ? "Untitled Macro" : manipulator.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let summary = primaryActionSummary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                // Keyboard shortcut hint
                let shortcut = manipulator.trigger.displayLabel
                if !shortcut.isEmpty && shortcut != "Not recorded" {
                    Text(shortcut)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                }

                // Chevron on hover
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .opacity(isHovering ? 1 : 0)
                    .frame(width: 12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        wasJustTriggered
                            ? Color.accentColor.opacity(0.15)
                            : isHovering
                                ? Color.accentColor.opacity(0.08)
                                : Color.clear
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
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
            Divider()
            Text("Trigger: \(manipulator.trigger.displayLabel)")
            Text("Actions: \(manipulator.actions.filter(\.isConfigured).count)")
            if !manipulator.tags.isEmpty {
                Text("Tags: \(manipulator.tags.sorted().joined(separator: ", "))")
            }
        }
    }

    private var triggerKeyLabel: String {
        // Show the key type symbol for non-keyboard, or the first key label
        if manipulator.trigger.keyType != .keyboard {
            return manipulator.trigger.keyType.symbol
        }
        if let firstKey = manipulator.trigger.steps.first?.displayLabel {
            return String(firstKey.prefix(4))
        }
        return manipulator.trigger.keyType.symbol
    }
}
