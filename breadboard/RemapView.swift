import SwiftUI

struct RemapView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        NavigationSplitView {
            ManipulatorSidebar(store: store)
                .navigationTitle("Manipulators")
        } detail: {
            ManipulatorEditorPane(store: store)
                .frame(minWidth: 560)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.addManipulator()
                } label: {
                    Label("Add Manipulator", systemImage: "plus")
                }
                .help("Add a new manipulator (⌘N)")
            }
            ToolbarItem(placement: .navigation) {
                Button {
                    store.importManipulatorFromPanel()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import a manipulator from a .breadboardmanipulator file (⌥⌘I)")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                ProfileSwitcherButton(store: store)
            }
        }
    }
}

private struct ManipulatorSidebar: View {
    @ObservedObject var store: RemapStore
    @State private var showFilterPopover = false
    @State private var groupByFolder = false
    @State private var activeOnly = false
    @State private var folderExpanded: [String: Bool] = [:]

    private var displayedManipulators: [Manipulator] {
        // Use debounced results for smoother UI when searching
        let base = store.debouncedFilteredManipulators
        if activeOnly {
            return base.filter { $0.isEnabled }
        }
        return base
    }

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilter
            Divider()
            manipulatorList
                .frame(maxHeight: .infinity)
            permissionBanner
        }
        .frame(minWidth: 280, maxWidth: 380)
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if store.remapNeedsPermission {
            VStack(alignment: .leading, spacing: 8) {
                Label("Accessibility Access Required", systemImage: "exclamationmark.shield.fill")
                    .font(.subheadline.weight(.medium))
                Text("Breadboard needs Accessibility permission to intercept keyboard events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button("Grant Permission") {
                        store.requestRemapPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Button("Open System Settings") {
                        store.openAccessibilitySettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .overlay(alignment: .top) {
                Divider()
            }
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(store.remapIsActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(store.remapStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3))
            .overlay(alignment: .top) {
                Divider()
            }
        }
    }

    private var searchAndFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Search manipulators", text: $store.searchText)
                .textFieldStyle(.plain)
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                }
                Button {
                    showFilterPopover.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Active only", isOn: $activeOnly)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        Toggle("Group by folder", isOn: $groupByFolder)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        if groupByFolder && !store.allFolders.isEmpty {
                            Divider()
                            Text("Folders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(store.allFolders, id: \.self) { folder in
                                Text(folder)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(12)
                    .frame(width: 180)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

            if !store.allTags.isEmpty {
                tagFilter
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var tagFilter: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !store.selectedTags.isEmpty {
                    Button("Clear") {
                        store.clearTagFilter()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            FlowLayout(spacing: 4) {
                ForEach(store.allTags, id: \.self) { tag in
                    TagChip(
                        label: tag,
                        isSelected: store.selectedTags.contains(tag),
                        action: { store.toggleTag(tag) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var manipulatorList: some View {
        if displayedManipulators.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView {
                    Text("No manipulators")
                } description: {
                    Text(store.searchText.isEmpty && store.selectedTags.isEmpty
                         ? "Add one to get started."
                         : "No manipulators match the current filter.")
                } actions: {
                    Button {
                        store.addManipulator()
                    } label: {
                        Text("Add Manipulator")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .frame(maxHeight: .infinity)
        } else if groupByFolder {
            let groups = Dictionary(grouping: displayedManipulators) {
                $0.folder.isEmpty ? "Uncategorized" : $0.folder
            }
            let sortedFolders = groups.keys.sorted()
            List(selection: $store.selectedManipulatorID) {
                ForEach(sortedFolders, id: \.self) { folder in
                    DisclosureGroup(isExpanded: expandedBinding(for: folder)) {
                        ForEach(groups[folder] ?? []) { manipulator in
                            ManipulatorRow(store: store, manipulator: manipulator)
                                .tag(manipulator.id)
                        }
                    } label: {
                        Text(folder)
                            .font(.headline)
                    }
                }
            }
            .listStyle(.sidebar)
        } else {
            List(selection: $store.selectedManipulatorID) {
                ForEach(displayedManipulators) { manipulator in
                    ManipulatorRow(store: store, manipulator: manipulator)
                        .tag(manipulator.id)
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func expandedBinding(for folder: String) -> Binding<Bool> {
        Binding(
            get: { folderExpanded[folder, default: true] },
            set: { folderExpanded[folder] = $0 }
        )
    }
}

private struct ManipulatorRow: View {
    @ObservedObject var store: RemapStore
    let manipulator: Manipulator

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                // Status indicator
                if !manipulator.isEnabled {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.caption2)
                }
                
                // Name - primary text
                Text(manipulator.name.isEmpty ? "Untitled" : manipulator.name)
                    .font(.body)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                // Trigger badge - compact
                if !manipulator.trigger.displayLabel.isEmpty {
                    Text(manipulator.trigger.displayLabel)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                }
            }
            
            // Secondary info line
            HStack(spacing: 4) {
                if !manipulator.notes.isEmpty {
                    Image(systemName: "text.alignleft")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(manipulator.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if !manipulator.tags.isEmpty {
                    Text(manipulator.tags.sorted().prefix(2).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(manipulator.isEnabled ? 1 : 0.55)
        .contextMenu {
            Button(manipulator.isEnabled ? "Disable" : "Enable") {
                store.updateManipulator(manipulator.id) { $0.isEnabled.toggle() }
            }
            Button("Duplicate") {
                store.duplicateManipulator(manipulator.id)
            }
            Divider()
            Button("Export…") {
                store.exportManipulator(manipulator.id)
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.deleteManipulator(manipulator.id)
            }
        }
    }
}

struct ManipulatorEditorPane: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        Group {
            if let manipulator = store.selectedManipulator {
                ManipulatorEditorView(store: store, manipulator: manipulator)
            } else {
                ContentUnavailableView {
                    Text("No Manipulator Selected")
                } description: {
                    Text("Add a manipulator or pick one from the list.")
                } actions: {
                    Button {
                        store.addManipulator()
                    } label: {
                        Text("Add Manipulator")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(store.selectedManipulator?.name ?? "Manipulator")
    }
}

private struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalWidth = max(totalWidth, rowWidth - spacing)
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, rowWidth - spacing)
        totalHeight += rowHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
