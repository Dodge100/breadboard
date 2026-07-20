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
                    Image(systemName: "plus")
                }
                .help("Add a new menu bar item")
            }
        }
    }
}

// MARK: - Sidebar

private struct MenuBarItemsSidebar: View {
    @ObservedObject var store: RemapStore
    @State private var itemToDelete: MenuBarItem?

    var body: some View {
        VStack(spacing: 0) {
            itemList
        }
        .frame(minWidth: 200, maxWidth: 380)
        .alert(
            "Delete \"\(itemToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Delete", role: .destructive) {
                if let id = itemToDelete?.id {
                    store.deleteMenuBarItem(id)
                }
                itemToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var itemList: some View {
        Group {
            if store.menuBarItems.isEmpty {
                ContentUnavailableView {
                    Label("No Menu Bar Items", systemImage: "menubar.rectangle")
                } description: {
                    Text("Add items to customize your Breadboard menu bar.")
                } actions: {
                    Button("Add Menu Item") {
                        store.addMenuBarItem()
                    }
                }
            } else {
                List(selection: $store.selectedMenuBarItemID) {
                    Section("Items (\(store.menuBarItems.count))") {
                        ForEach(store.menuBarItems) { item in
                            MenuBarItemRow(store: store, item: item)
                                .tag(item.id)
                                .contextMenu {
                                    contextMenuItems(for: item)
                                }
                        }
                        .onMove { source, dest in
                            store.moveMenuBarItem(from: source, to: dest)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                itemToDelete = store.menuBarItems[index]
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private func contextMenuItems(for item: MenuBarItem) -> some View {
        Button {
            store.toggleMenuBarItemEnabled(item.id)
        } label: {
            Text(item.isEnabled ? "Disable" : "Enable")
        }

        if !item.isSeparator {
            Button {
                store.addMenuBarChildItem(to: item.id)
                store.selectedMenuBarItemID = item.id
            } label: {
                Text("Add Sub-item")
            }
        }

        Button {
            store.toggleMenuBarItemSeparator(item.id)
        } label: {
            Text(item.isSeparator ? "Convert to Item" : "Make Separator")
        }

        Button {
            store.duplicateMenuBarItem(item.id)
        } label: {
            Text("Duplicate")
        }

        Divider()

        Button(role: .destructive) {
            itemToDelete = item
        } label: {
            Text("Delete")
        }
    }
}

// MARK: - Menu Bar Item Row

private struct MenuBarItemRow: View {
    @ObservedObject var store: RemapStore
    let item: MenuBarItem

    var body: some View {
        HStack(spacing: 8) {
            if item.isSeparator {
                Text("—")
                    .foregroundStyle(.tertiary)
                    .frame(width: 16)
                Text("Separator")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: item.icon)
                    .foregroundStyle(item.isEnabled ? .secondary : .tertiary)
                    .frame(width: 16)
                Text(item.name)
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)

                Spacer()

                if !item.isEnabled {
                    Text("OFF")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.red.opacity(0.1))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Editor Pane

private struct MenuBarItemEditorPane: View {
    @ObservedObject var store: RemapStore
    @State private var showIconPicker = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if let item = store.selectedMenuBarItem {
                editorContent(item: item)
            } else {
                ContentUnavailableView {
                    Label("No Item Selected", systemImage: "menubar.rectangle")
                } description: {
                    Text("Select a menu bar item from the sidebar.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(
            "Delete \"\(store.selectedMenuBarItem?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let id = store.selectedMenuBarItemID {
                    store.deleteMenuBarItem(id)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func editorContent(item: MenuBarItem) -> some View {
        let binding = Binding(
            get: { item },
            set: { newItem in
                if let idx = store.menuBarItems.firstIndex(where: { $0.id == newItem.id }) {
                    store.menuBarItems[idx] = newItem
                    store.saveMenuBarItems()
                }
            }
        )

        return VStack(alignment: .leading, spacing: 0) {
            // Single row: icon + name + enable toggle + delete
            HStack(spacing: 10) {
                Button {
                    showIconPicker.toggle()
                } label: {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showIconPicker) {
                    IconPickerView(item: binding)
                }

                TextField("Name", text: binding.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                Toggle("", isOn: binding.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .help(item.isEnabled ? "Enabled" : "Disabled")

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete this item")
            }
            .padding(.vertical, 12)

            Divider()

            // Actions — inline, no wrapper
            VStack(alignment: .leading, spacing: 0) {
                actionRow(
                    label: "Left Click",
                    action: Binding(
                        get: { item.leftClickAction ?? MenuBarItemAction() },
                        set: { binding.wrappedValue.leftClickAction = $0; store.saveMenuBarItems() }
                    ),
                    onClear: { binding.wrappedValue.leftClickAction = nil; store.saveMenuBarItems() }
                )

                Divider().padding(.leading, 80)

                actionRow(
                    label: "Right Click (⌥)",
                    action: Binding(
                        get: { item.rightClickAction ?? MenuBarItemAction() },
                        set: { binding.wrappedValue.rightClickAction = $0; store.saveMenuBarItems() }
                    ),
                    onClear: { binding.wrappedValue.rightClickAction = nil; store.saveMenuBarItems() }
                )
            }
            .padding(.vertical, 12)

            // Sub-items — inline list
            if !item.isSeparator && !item.children.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(item.children.enumerated()), id: \.element.id) { index, child in
                        if index > 0 { Divider().padding(.leading, 80) }
                        MenuBarChildRow(
                            child: child,
                            parentItem: item,
                            store: store
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Action Row

    private func actionRow(
        label: String,
        action: Binding<MenuBarItemAction>,
        onClear: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Picker("", selection: action.kind) {
                        ForEach(MenuBarActionKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)

                    if action.wrappedValue.kind != .none {
                        Button("Clear", action: onClear)
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                actionParameters(action: action)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func actionParameters(action: Binding<MenuBarItemAction>) -> some View {
        switch action.wrappedValue.kind {
        case .none:
            EmptyView()
        case .runShortcut:
            TextField("Shortcut name", text: action.shortcutName, prompt: Text("e.g. Open Browser"))
                .textFieldStyle(.roundedBorder)
        case .runShell:
            TextField("Command", text: action.shellCommand, prompt: Text("e.g. echo hello"), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())
        case .openApp:
            HStack(spacing: 8) {
                TextField("Bundle ID", text: action.appBundleID, prompt: Text("com.apple.Safari"))
                    .textFieldStyle(.roundedBorder)
                TextField("App Name", text: action.appName, prompt: Text("Safari"))
                    .textFieldStyle(.roundedBorder)
            }
        case .openURL:
            TextField("URL", text: action.urlString, prompt: Text("https://example.com"))
                .textFieldStyle(.roundedBorder)
        case .sendKey:
            HStack(spacing: 8) {
                TextField("Key", text: action.toKey, prompt: Text("a, space, return"))
                    .textFieldStyle(.roundedBorder)
                HStack(spacing: 2) {
                    ForEach(ModifierKey.flagBased, id: \.self) { mod in
                        Toggle(mod.symbol, isOn: Binding(
                            get: { action.wrappedValue.toModifiers.contains(mod) },
                            set: {
                                if $0 { action.wrappedValue.toModifiers.insert(mod) }
                                else { action.wrappedValue.toModifiers.remove(mod) }
                                store.saveMenuBarItems()
                            }
                        ))
                        .toggleStyle(.button)
                        .controlSize(.small)
                    }
                }
            }
        case .setVariable:
            HStack(spacing: 8) {
                TextField("Variable", text: action.variableName, prompt: Text("myVar"))
                    .textFieldStyle(.roundedBorder)
                TextField("Value", text: action.variableValue, prompt: Text("some value"))
                    .textFieldStyle(.roundedBorder)
            }
        case .toggleVariable:
            TextField("Variable", text: action.variableName, prompt: Text("myVar"))
                .textFieldStyle(.roundedBorder)
        case .incrementVariable:
            HStack(spacing: 8) {
                TextField("Variable", text: action.variableName, prompt: Text("counter"))
                    .textFieldStyle(.roundedBorder)
                TextField("Step", text: action.variableValue, prompt: Text("1"))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 80)
            }
        case .setNotification:
            TextField("Message", text: action.notificationMessage, prompt: Text("Hello from Breadboard!"), axis: .vertical)
                .textFieldStyle(.roundedBorder)
        case .openFile:
            TextField("File path", text: action.filePath, prompt: Text("~/Documents"))
                .textFieldStyle(.roundedBorder)
        case .runAppleScript:
            TextEditor(text: action.scriptBody)
                .font(.caption.monospaced())
                .frame(minHeight: 60, maxHeight: 120)
                .border(.quaternary)
        }
    }
}

// MARK: - Menu Bar Child Row

private struct MenuBarChildRow: View {
    let child: MenuBarItem
    let parentItem: MenuBarItem
    @ObservedObject var store: RemapStore
    @State private var showIconPicker = false
    @State private var childToDelete: MenuBarItem?

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showIconPicker.toggle()
            } label: {
                Image(systemName: child.icon)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showIconPicker) {
                IconPickerGrid(icon: Binding(
                    get: { child.icon },
                    set: { newIcon in
                        store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.icon = newIcon }
                    }
                ))
            }

            TextField("Name", text: Binding(
                get: { child.name },
                set: { newValue in
                    store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.name = newValue }
                }
            ))
            .textFieldStyle(.plain)

            Spacer()

            Toggle("", isOn: Binding(
                get: { child.isEnabled },
                set: { _ in store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.isEnabled.toggle() } }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.isEnabled.toggle() }
            } label: {
                Text(child.isEnabled ? "Disable" : "Enable")
            }

            Button {
                store.addMenuBarChildItem(to: child.id)
            } label: {
                Text("Add Sub-item")
            }

            Divider()

            Button(role: .destructive) {
                childToDelete = child
            } label: {
                Text("Delete")
            }
        }
        .alert(
            "Delete \"\(childToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { childToDelete != nil },
                set: { if !$0 { childToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { childToDelete = nil }
            Button("Delete", role: .destructive) {
                if let id = childToDelete?.id {
                    store.deleteMenuBarChildItem(id, from: parentItem.id)
                }
                childToDelete = nil
            }
        }
    }
}

// MARK: - Icon Picker (reusable grid)

private struct IconPickerGrid: View {
    @Binding var icon: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6),
                spacing: 4
            ) {
                ForEach(MenuBarItem.availableIcons, id: \.self) { candidate in
                    Button {
                        icon = candidate
                        dismiss()
                    } label: {
                        Image(systemName: candidate)
                            .font(.body)
                            .frame(width: 28, height: 28)
                            .background(
                                candidate == icon
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                            )
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(width: 220, height: 260)
    }
}

// MARK: - Icon Picker (for top-level items)

private struct IconPickerView: View {
    @Binding var item: MenuBarItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        IconPickerGrid(icon: $item.icon)
    }
}
