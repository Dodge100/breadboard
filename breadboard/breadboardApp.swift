import SwiftUI

struct breadboardApp: App {
    @StateObject private var store = RemapStore()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: store)
                .frame(minWidth: 1100, minHeight: 700)
                .frame(idealWidth: 1280, idealHeight: 800)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Breadboard", systemImage: "keyboard") {
            DynamicMenuBarContent(store: store)
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Dynamic Menu Bar Content

private struct DynamicMenuBarContent: View {
    @ObservedObject var store: RemapStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let items = store.menuBarItems.filter { $0.isEnabled }

        if items.isEmpty {
            Button("Show Breadboard") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Open Menu Bar Items Editor") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        } else {
            ForEach(items) { item in
                MenuBarItemView(store: store, item: item)
            }
            Divider()
            Button("Show Breadboard") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

// MARK: - Menu Bar Item View

private struct MenuBarItemView: View {
    @ObservedObject var store: RemapStore
    let item: MenuBarItem
    @State private var isHovering = false

    var body: some View {
        if item.isSeparator {
            Divider()
        } else if !item.children.isEmpty {
            // Submenu
            Menu {
                ForEach(item.children.filter(\.isEnabled)) { child in
                    MenuBarActionButton(store: store, item: child)
                }
            } label: {
                Label(item.name, systemImage: item.icon)
            }
        } else {
            // Action item
            MenuBarActionButton(store: store, item: item)
        }
    }
}

// MARK: - Menu Bar Action Button

private struct MenuBarActionButton: View {
    @ObservedObject var store: RemapStore
    let item: MenuBarItem

    var body: some View {
        Button {
            // Determine which action to use based on modifier keys
            // If Option key is held, use right-click action, otherwise left-click
            let useRightClick = NSEvent.modifierFlags.contains(.option)
            if useRightClick, let action = item.rightClickAction, action.kind != .none {
                store.executeMenuBarAction(action)
            } else if let action = item.leftClickAction, action.kind != .none {
                store.executeMenuBarAction(action)
            }
        } label: {
            if item.hasRightAction {
                // Show both actions in the label
                Label {
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("⌥ for right action")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: item.icon)
                }
            } else {
                Label(item.name, systemImage: item.icon)
            }
        }
        .help(buildHelpText())
    }

    private func buildHelpText() -> String {
        var parts: [String] = []
        if let left = item.leftClickAction, left.kind != .none {
            parts.append("Left click: \(left.summary)")
        }
        if let right = item.rightClickAction, right.kind != .none {
            parts.append("Option+click: \(right.summary)")
        }
        return parts.joined(separator: " | ")
    }
}
