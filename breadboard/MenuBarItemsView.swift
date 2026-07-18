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
        .frame(minWidth: 200)
        .alert("Delete \"\(itemToDelete?.name ?? "")\"?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
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
                    Section("Menu Bar Items (\(store.menuBarItems.count))") {
                        ForEach(store.menuBarItems) { item in
                            MenuBarItemRow(store: store, item: item, level: 0)
                                .tag(item.id)
                                .contextMenu {
                                    Button {
                                        store.selectedMenuBarItemID = item.id
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Divider()

                                    Button {
                                        store.toggleMenuBarItemEnabled(item.id)
                                    } label: {
                                        Label(
                                            item.isEnabled ? "Disable" : "Enable",
                                            systemImage: item.isEnabled ? "pause" : "play"
                                        )
                                    }

                                    Button {
                                        store.toggleMenuBarItemSeparator(item.id)
                                    } label: {
                                        Label(
                                            item.isSeparator ? "Convert to Item" : "Convert to Separator",
                                            systemImage: item.isSeparator ? "rectangle" : "minus"
                                        )
                                    }

                                    if !item.isSeparator {
                                        Button {
                                            store.addMenuBarChildItem(to: item.id)
                                            store.selectedMenuBarItemID = item.id
                                        } label: {
                                            Label("Add Sub-item", systemImage: "plus")
                                        }
                                    }

                                    Divider()

                                    Button {
                                        store.duplicateMenuBarItem(item.id)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        itemToDelete = item
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: item.icon)
                    .foregroundStyle(item.isEnabled ? .secondary : .tertiary)
                    .frame(width: 16)
                Text(item.name)
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)

                if !item.children.isEmpty {
                    Text("\(item.children.count)")
                        .font(.caption).foregroundStyle(.tertiary)
                }

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

                Text(item.summary)
                    .font(.caption).foregroundStyle(.tertiary)
                    .lineLimit(1)
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
        .alert("Delete \"\(store.selectedMenuBarItem?.name ?? "")\"?", isPresented: $showDeleteConfirmation) {
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

        return VStack(alignment: .leading, spacing: 20) {
            header(item: item, binding: binding)
            actionsSection(item: item, binding: binding)
            childrenSection(item: item)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: 600, alignment: .leading)
    }

    private func header(item: MenuBarItem, binding: Binding<MenuBarItem>) -> some View {
        HStack(spacing: 12) {
            Button {
                showIconPicker.toggle()
            } label: {
                Image(systemName: item.icon)
                    .font(.title2)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showIconPicker) { IconPickerView(item: binding) }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Item Name", text: binding.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .frame(maxWidth: 300)

                HStack(spacing: 12) {
                    Toggle("Enabled", isOn: binding.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    if !item.isSeparator {
                        Toggle("Separator", isOn: Binding(
                            get: { item.isSeparator },
                            set: { if $0 { store.toggleMenuBarItemSeparator(item.id) } }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if !item.isSeparator {
                    Button {
                        store.addMenuBarChildItem(to: item.id)
                    } label: {
                        Label("Add Sub-item", systemImage: "plus")
                            .font(.caption)
                    }
                    .help("Add a sub-item to this menu item")
                }

                Button {
                    store.duplicateMenuBarItem(item.id)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .help("Create a copy of this item")

                Divider().frame(height: 16)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .help("Delete this item")
            }
        }
    }

    private func actionsSection(item: MenuBarItem, binding: Binding<MenuBarItem>) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 20) {
                    actionEditor(label: "Left Click", action: Binding(
                        get: { item.leftClickAction ?? MenuBarItemAction() },
                        set: { binding.wrappedValue.leftClickAction = $0; store.saveMenuBarItems() }
                    ), onClear: { binding.wrappedValue.leftClickAction = nil; store.saveMenuBarItems() })

                    Divider().frame(height: 120)

                    actionEditor(label: "Right Click (⌥)", action: Binding(
                        get: { item.rightClickAction ?? MenuBarItemAction() },
                        set: { binding.wrappedValue.rightClickAction = $0; store.saveMenuBarItems() }
                    ), onClear: { binding.wrappedValue.rightClickAction = nil; store.saveMenuBarItems() })
                }
            }
            .padding(8)
        } label: {
            Label("Actions", systemImage: "cursorarrow.click")
        }
    }

    private func actionEditor(label: String, action: Binding<MenuBarItemAction>, onClear: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                if action.wrappedValue.kind != .none {
                    Button("Clear", action: onClear)
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Picker("Kind", selection: action.kind) {
                ForEach(MenuBarActionKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 200)

            actionParameters(action: action)
        }
    }

    @ViewBuilder
    private func actionParameters(action: Binding<MenuBarItemAction>) -> some View {
        switch action.wrappedValue.kind {
        case .none: EmptyView()
        case .runShortcut:
            TextField("Shortcut Name", text: action.shortcutName, prompt: Text("e.g. Open Browser"))
                .textFieldStyle(.roundedBorder)
        case .runShell:
            TextField("Command", text: action.shellCommand, prompt: Text("e.g. echo hello"), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())
        case .openApp:
            VStack(alignment: .leading) {
                TextField("Bundle ID", text: action.appBundleID, prompt: Text("com.apple.Safari"))
                    .textFieldStyle(.roundedBorder)
                TextField("App Name", text: action.appName, prompt: Text("Safari"))
                    .textFieldStyle(.roundedBorder)
            }
        case .openURL:
            TextField("URL", text: action.urlString, prompt: Text("https://example.com"))
                .textFieldStyle(.roundedBorder)
        case .sendKey:
            TextField("Key", text: action.toKey, prompt: Text("a, space, return"))
                .textFieldStyle(.roundedBorder)
            Text("Modifiers").font(.caption)
            HStack(spacing: 4) {
                ForEach(ModifierKey.flagBased, id: \.self) { mod in
                    Toggle(mod.symbol, isOn: Binding(
                        get: { action.wrappedValue.toModifiers.contains(mod) },
                        set: { if $0 { action.wrappedValue.toModifiers.insert(mod) }
                               else { action.wrappedValue.toModifiers.remove(mod) }
                               store.saveMenuBarItems() }
                    ))
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
            }
        case .setVariable:
            TextField("Variable Name", text: action.variableName, prompt: Text("myVar"))
                .textFieldStyle(.roundedBorder)
            TextField("Value", text: action.variableValue, prompt: Text("some value"))
                .textFieldStyle(.roundedBorder)
        case .toggleVariable:
            TextField("Variable Name", text: action.variableName, prompt: Text("myVar"))
                .textFieldStyle(.roundedBorder)
        case .incrementVariable:
            TextField("Variable Name", text: action.variableName, prompt: Text("counter"))
                .textFieldStyle(.roundedBorder)
            TextField("Step", text: action.variableValue, prompt: Text("1"))
                .textFieldStyle(.roundedBorder)
        case .setNotification:
            TextField("Message", text: action.notificationMessage, prompt: Text("Hello from Breadboard!"), axis: .vertical)
                .textFieldStyle(.roundedBorder)
        case .openFile:
            TextField("File Path", text: action.filePath, prompt: Text("~/Documents"))
                .textFieldStyle(.roundedBorder)
        case .runAppleScript:
            TextEditor(text: action.scriptBody)
                .font(.caption.monospaced())
                .frame(minHeight: 80, maxHeight: 150)
                .border(.quaternary)
        }
    }

    private func childrenSection(item: MenuBarItem) -> some View {
        Group {
            if !item.children.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(item.children.enumerated()), id: \.element.id) { index, child in
                            MenuBarChildRow(
                                child: child,
                                parentItem: item,
                                store: store,
                                index: index
                            )
                            if index < item.children.count - 1 {
                                Divider()
                            }
                        }
                    }
                } label: {
                    HStack {
                        Label("Sub-items (\(item.children.count))", systemImage: "list.bullet")
                        Spacer()
                        Button {
                            store.addMenuBarChildItem(to: item.id)
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Add sub-item")
                    }
                }
            }
        }
    }
}

// MARK: - Menu Bar Child Row

private struct MenuBarChildRow: View {
    let child: MenuBarItem
    let parentItem: MenuBarItem
    @ObservedObject var store: RemapStore
    let index: Int
    @State private var isExpanded = false
    @State private var showIconPicker = false
    @State private var childToDelete: MenuBarItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Expand/collapse if has children
                if !child.children.isEmpty {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 12)
                }

                // Icon
                Button {
                    showIconPicker.toggle()
                } label: {
                    Image(systemName: child.icon)
                        .font(.body)
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showIconPicker) {
                    // Simple icon picker for child items
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                            ForEach(MenuBarItem.availableIcons, id: \.self) { icon in
                                Button {
                                    store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.icon = icon }
                                    showIconPicker = false
                                } label: {
                                    Image(systemName: icon)
                                        .font(.body)
                                        .frame(width: 24, height: 24)
                                        .background(icon == child.icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                    .frame(width: 200, height: 200)
                }

                // Name
                TextField("Name", text: Binding(
                    get: { child.name },
                    set: { newValue in
                        store.updateMenuBarChildItem(child.id, in: parentItem.id) { item in
                            item.name = newValue
                        }
                    }
                ))
                .textFieldStyle(.plain)
                .font(.body)

                Spacer()

                // Summary
                Text(child.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Enabled toggle
                Toggle("", isOn: Binding(
                    get: { child.isEnabled },
                    set: { _ in store.updateMenuBarChildItem(child.id, in: parentItem.id) { $0.isEnabled.toggle() } }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()

                // Delete button
                Button {
                    childToDelete = child
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .help("Delete sub-item")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)

            // Sub-children if expanded
            if isExpanded && !child.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(child.children.enumerated()), id: \.element.id) { subIndex, subChild in
                        MenuBarChildRow(
                            child: subChild,
                            parentItem: child,
                            store: store,
                            index: subIndex
                        )
                    }
                }
                .padding(.leading, 28)
            }
        }
        .background(isExpanded ? Color.accentColor.opacity(0.03) : Color.clear)
        .alert("Delete \"\(childToDelete?.name ?? "")\"?", isPresented: Binding(
            get: { childToDelete != nil },
            set: { if !$0 { childToDelete = nil } }
        )) {
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

// MARK: - Icon Picker

private struct IconPickerView: View {
    @Binding var item: MenuBarItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(MenuBarItem.availableIcons, id: \.self) { icon in
                    Button {
                        item.icon = icon
                        dismiss()
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(icon == item.icon ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(width: 300, height: 350)
    }
}
