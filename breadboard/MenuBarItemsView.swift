import SwiftUI

// MARK: - Main Menu Bar Items View

struct MenuBarItemsView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        NavigationSplitView {
            MenuBarItemsSidebar(store: store)
                .navigationTitle("Menu Bar Items")
        } detail: {
            MenuBarItemEditorPane(store: store)
                .frame(minWidth: 520)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.addMenuBarItem()
                } label: {
                    Label("Add Menu Item", systemImage: "plus")
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.saveMenuBarItems()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .help("Save menu bar items")
            }
        }
    }
}

// MARK: - Sidebar

private struct MenuBarItemsSidebar: View {
    @ObservedObject var store: RemapStore
    @State private var showFilterPopover = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            itemList
                .frame(maxHeight: .infinity)
            bottomBar
        }
        .frame(minWidth: 260, maxWidth: 360)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField("Search menu items", text: .constant(""))
                .textFieldStyle(.plain)
                .disabled(true)
                .help("Search coming soon")
            Button {
                showFilterPopover.toggle()
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No filters available yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(width: 180)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var itemList: some View {
        Group {
            if store.menuBarItems.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView {
                        Text("No menu bar items")
                    } description: {
                        Text("Add items to customize your Breadboard menu bar menu.")
                    } actions: {
                        Button {
                            store.addMenuBarItem()
                        } label: {
                            Text("Add Menu Item")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                List(selection: $store.selectedMenuBarItemID) {
                    ForEach(store.menuBarItems) { item in
                        MenuBarItemRow(store: store, item: item, level: 0)
                            .tag(item.id)
                    }
                    .onMove { source, dest in
                        store.moveMenuBarItem(from: source, to: dest)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 6) {
            Text("\(store.menuBarItems.count) item\(store.menuBarItems.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.3))
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Menu Bar Item Row

private struct MenuBarItemRow: View {
    @ObservedObject var store: RemapStore
    let item: MenuBarItem
    let level: Int

    var body: some View {
        HStack(spacing: 6) {
            if level > 0 {
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: CGFloat(level) * 12, height: 1)
            }

            if item.isSeparator {
                Image(systemName: "minus")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                Text("Separator")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Image(systemName: item.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(item.name.isEmpty ? "Untitled" : item.name)
                    .font(.body)
                    .lineLimit(1)
                Spacer(minLength: 4)

                if !item.children.isEmpty {
                    Text("\u{2192}\(item.children.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else if item.hasLeftAction {
                    Text(item.leftClickAction?.summary ?? "")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !item.isEnabled {
                    Image(systemName: "pause.circle")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(item.isEnabled ? 1 : 0.55)
        .contextMenu {
            Button(item.isSeparator ? "Convert to item" : "Toggle Separator") {
                store.toggleMenuBarItemSeparator(item.id)
            }
            Button("Duplicate") {
                store.duplicateMenuBarItem(item.id)
            }
            if !item.isSeparator {
                Button("Add Sub-Item") {
                    store.addMenuBarChildItem(to: item.id)
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.deleteMenuBarItem(item.id)
            }
        }
    }
}

// MARK: - Editor Pane

private struct MenuBarItemEditorPane: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        Group {
            if let item = store.selectedMenuBarItem {
                MenuBarItemEditorView(store: store, item: item)
            } else {
                ContentUnavailableView {
                    Text("No Menu Item Selected")
                } description: {
                    Text("Add a menu bar item or pick one from the list.")
                } actions: {
                    Button {
                        store.addMenuBarItem()
                    } label: {
                        Text("Add Menu Item")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(store.selectedMenuBarItem?.name ?? "Menu Bar Items")
    }
}

// MARK: - Menu Bar Item Editor

private struct MenuBarItemEditorView: View {
    @ObservedObject var store: RemapStore
    let item: MenuBarItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if !item.isSeparator {
                    actionsSection
                    subItemsSection
                }
            }
            .padding(20)
            .frame(maxWidth: 660, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon picker
                IconPickerView(selectedIcon: item.icon) { newIcon in
                    store.updateSelectedMenuBarItem { $0.icon = newIcon }
                }

                TextField("Menu item name", text: nameBinding)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)

                Spacer()

                Toggle("Enabled", isOn: enabledBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Toggle("Show as separator", isOn: separatorBinding)
                .toggleStyle(.switch)
                .controlSize(.small)

            if item.isSeparator {
                Text("Separators appear as divider lines in the menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionsSection: some View {
        if !item.children.isEmpty {
            HStack {
                Image(systemName: "info.circle")
                Text("This item has sub-items. Click actions are disabled when sub-items are present.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }

        GroupBox(label: Label("Left Click Action", systemImage: "cursorarrow.click")) {
            ActionEditorView(
                action: leftActionBinding,
                onClear: {
                    store.updateSelectedMenuBarItem { $0.leftClickAction = nil }
                }
            )
        }
        .disabled(!item.children.isEmpty)

        GroupBox(label: Label("Right Click Action", systemImage: "cursorarrow.click.2")) {
            ActionEditorView(
                action: rightActionBinding,
                onClear: {
                    store.updateSelectedMenuBarItem { $0.rightClickAction = nil }
                }
            )
        }
        .disabled(!item.children.isEmpty)
    }

    // MARK: - Sub-items

    @ViewBuilder
    private var subItemsSection: some View {
        if !item.children.isEmpty {
            GroupBox(label: Label("Sub-items (\(item.children.count))", systemImage: "list.bullet")) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.children) { child in
                        SubItemRow(store: store, parentID: item.id, child: child)
                    }

                    Button {
                        store.addMenuBarChildItem(to: item.id)
                    } label: {
                        Label("Add Sub-Item", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    .font(.body)
                }
            }
        }
    }

    // MARK: - Bindings

    private var nameBinding: Binding<String> {
        Binding(
            get: { item.name },
            set: { newValue in
                store.updateSelectedMenuBarItem { item in
                    item.name = newValue
                }
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { item.isEnabled },
            set: { newValue in
                store.updateSelectedMenuBarItem { item in
                    item.isEnabled = newValue
                }
            }
        )
    }

    private var separatorBinding: Binding<Bool> {
        Binding(
            get: { item.isSeparator },
            set: { _ in store.toggleMenuBarItemSeparator(item.id) }
        )
    }

    private var leftActionBinding: Binding<MenuBarItemAction> {
        Binding(
            get: { item.leftClickAction ?? MenuBarItemAction(kind: .none) },
            set: { newAction in
                store.updateSelectedMenuBarItem { item in
                    item.leftClickAction = newAction.kind == .none ? nil : newAction
                }
            }
        )
    }

    private var rightActionBinding: Binding<MenuBarItemAction> {
        Binding(
            get: { item.rightClickAction ?? MenuBarItemAction(kind: .none) },
            set: { newAction in
                store.updateSelectedMenuBarItem { item in
                    item.rightClickAction = newAction.kind == .none ? nil : newAction
                }
            }
        )
    }
}

// MARK: - Icon Picker

private struct IconPickerView: View {
    let selectedIcon: String
    let onSelect: (String) -> Void

    @State private var isShowing = false

    var body: some View {
        Button {
            isShowing = true
        } label: {
            Image(systemName: selectedIcon)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Choose an icon")
        .popover(isPresented: $isShowing, arrowEdge: .trailing) {
            iconGrid
        }
    }

    private var iconGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 6) {
                ForEach(MenuBarItem.availableIcons, id: \.self) { icon in
                    Button {
                        onSelect(icon)
                        isShowing = false
                    } label: {
                        Image(systemName: icon)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .help(icon)
                }
            }
            .padding(8)
        }
        .frame(width: 280, height: 300)
    }
}

// MARK: - Sub-Item Row

private struct SubItemRow: View {
    @ObservedObject var store: RemapStore
    let parentID: UUID
    let child: MenuBarItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Name", text: nameBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)

                IconPickerView(selectedIcon: child.icon) { newIcon in
                    store.updateMenuBarChildItem(child.id, in: parentID) { item in
                        item.icon = newIcon
                    }
                }

                Toggle("Enabled", isOn: enabledBinding)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()

                Button(role: .destructive) {
                    store.deleteMenuBarChildItem(child.id, from: parentID)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete sub-item")
            }

            GroupBox(label: Text("Left Click").font(.caption)) {
                ActionEditorView(
                    action: leftActionBinding,
                    onClear: {
                        store.updateMenuBarChildItem(child.id, in: parentID) { item in
                            item.leftClickAction = nil
                        }
                    }
                )
            }

            GroupBox(label: Text("Right Click").font(.caption)) {
                ActionEditorView(
                    action: rightActionBinding,
                    onClear: {
                        store.updateMenuBarChildItem(child.id, in: parentID) { item in
                            item.rightClickAction = nil
                        }
                    }
                )
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { child.name },
            set: { newValue in
                store.updateMenuBarChildItem(child.id, in: parentID) { item in
                    item.name = newValue
                }
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { child.isEnabled },
            set: { newValue in
                store.updateMenuBarChildItem(child.id, in: parentID) { item in
                    item.isEnabled = newValue
                }
            }
        )
    }

    private var leftActionBinding: Binding<MenuBarItemAction> {
        Binding(
            get: { child.leftClickAction ?? MenuBarItemAction(kind: .none) },
            set: { newAction in
                store.updateMenuBarChildItem(child.id, in: parentID) { item in
                    item.leftClickAction = newAction.kind == .none ? nil : newAction
                }
            }
        )
    }

    private var rightActionBinding: Binding<MenuBarItemAction> {
        Binding(
            get: { child.rightClickAction ?? MenuBarItemAction(kind: .none) },
            set: { newAction in
                store.updateMenuBarChildItem(child.id, in: parentID) { item in
                    item.rightClickAction = newAction.kind == .none ? nil : newAction
                }
            }
        )
    }
}

// MARK: - Action Editor

private struct ActionEditorView: View {
    @Binding var action: MenuBarItemAction
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Picker("Action", selection: $action.kind) {
                    ForEach(MenuBarActionKind.allCases) { kind in
                        HStack {
                            Image(systemName: kind.icon)
                            Text(kind.rawValue)
                        }
                        .tag(kind)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 160)

                Spacer()

                if action.kind != .none {
                    Button(role: .destructive) {
                        onClear()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove this action")
                }
            }

            if action.kind != .none {
                actionParameters
            }
        }
    }

    @ViewBuilder
    private var actionParameters: some View {
        switch action.kind {
        case .none:
            EmptyView()

        case .runShortcut:
            labelField(label: "Shortcut Name", text: $action.shortcutName, placeholder: "e.g. Open Browser")

        case .runShell:
            VStack(alignment: .leading, spacing: 4) {
                labelField(label: "Command", text: $action.shellCommand, placeholder: "e.g. echo hello", isVertical: true)
                Text("Runs a shell command (sh -c). Supports ~/ paths.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .openApp:
            VStack(alignment: .leading, spacing: 6) {
                labelField(label: "Bundle ID", text: $action.appBundleID, placeholder: "com.apple.Safari")
                labelField(label: "App Name", text: $action.appName, placeholder: "Safari")
                Text("Provide either the bundle identifier or the display name.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .openURL:
            VStack(alignment: .leading, spacing: 4) {
                labelField(label: "URL", text: $action.urlString, placeholder: "https://example.com")
                Text("Opens the URL in the default browser.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .sendKey:
            VStack(alignment: .leading, spacing: 8) {
                labelField(label: "Key", text: $action.toKey, placeholder: "e.g. a, space, return")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modifiers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(ModifierKey.flagBased, id: \.self) { mod in
                            Button {
                                if action.toModifiers.contains(mod) {
                                    action.toModifiers.remove(mod)
                                } else {
                                    action.toModifiers.insert(mod)
                                }
                            } label: {
                                Text(mod.symbol)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(action.toModifiers.contains(mod) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

        case .setVariable:
            VStack(alignment: .leading, spacing: 6) {
                labelField(label: "Variable Name", text: $action.variableName, placeholder: "myVar")
                labelField(label: "Value", text: $action.variableValue, placeholder: "some value")
                Text("Sets a Breadboard variable that can be used in conditions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .toggleVariable:
            labelField(label: "Variable Name", text: $action.variableName, placeholder: "myVar")
                .help("Toggles a variable between true and false")

        case .incrementVariable:
            VStack(alignment: .leading, spacing: 6) {
                labelField(label: "Variable Name", text: $action.variableName, placeholder: "counter")
                labelField(label: "Step (default 1)", text: $action.variableValue, placeholder: "1")
            }

        case .setNotification:
            VStack(alignment: .leading, spacing: 4) {
                labelField(label: "Message", text: $action.notificationMessage, placeholder: "Hello from Breadboard!", isVertical: true)
                Text("Shows a macOS notification with the given message.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .openFile:
            VStack(alignment: .leading, spacing: 4) {
                labelField(label: "File Path", text: $action.filePath, placeholder: "~/Documents or /Applications")
                Text("Opens the file or folder in Finder. Supports ~/ paths.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .runAppleScript:
            VStack(alignment: .leading, spacing: 4) {
                Text("AppleScript")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $action.scriptBody)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 80, maxHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                Text("Enter AppleScript source code. Runs via osascript.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func labelField(label: String, text: Binding<String>, placeholder: String = "", isVertical: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if isVertical {
                TextField(placeholder, text: text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
}

// MARK: - Modifier display

extension ModifierKey {
    var displayName: String {
        switch self {
        case .command: return "\u{2318}"
        case .shift: return "\u{21E7}"
        case .option: return "\u{2325}"
        case .control: return "\u{2303}"
        case .capsLock: return "\u{21EA}"
        case .fn: return "fn"
        }
    }
}
