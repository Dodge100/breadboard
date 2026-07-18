import SwiftUI
import AppKit
import Combine

// MARK: - Status Bar Controller
// Each enabled MenuBarItem becomes its own icon in the macOS menu bar.

final class StatusBarController: NSObject {
    static let shared = StatusBarController()
    private var statusItems: [UUID: NSStatusItem] = [:]
    /// Maps button pointer -> item ID so we can retrieve the item on click.
    private var buttonItemMap: [UnsafeMutableRawPointer: UUID] = [:]
    private var store: RemapStore?
    private var cancellables: Set<AnyCancellable> = []

    /// Install the initial "Breadboard" status item so the app has a presence.
    func install() {
        guard statusItems.isEmpty else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Breadboard")
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Starting…", action: nil, keyEquivalent: "")
        item.menu = menu
        statusItems[UUID()] = item
    }

    /// Attach the store and rebuild all status items based on menuBarItems.
    func attach(store: RemapStore) {
        guard self.store == nil else {
            self.store = store
            rebuildAll()
            return
        }
        self.store = store
        rebuildAll()

        store.$menuBarItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildAll()
            }
            .store(in: &cancellables)
    }

    // MARK: - Rebuild

    func rebuildAll() {
        guard let store else { return }

        let items = store.menuBarItems.filter { $0.isEnabled }

        // Remove status items that are no longer in the list
        let activeIDs = Set(items.map(\.id))
        for (id, item) in statusItems where !activeIDs.contains(id) {
            NSStatusBar.system.removeStatusItem(item)
            statusItems.removeValue(forKey: id)
        }

        // Always keep at least one item so the app doesn't disappear
        if items.isEmpty {
            ensureFallbackItem()
            return
        }

        // Create or update status items for each enabled MenuBarItem
        for menuItem in items {
            let statusItem: NSStatusItem
            if let existing = statusItems[menuItem.id] {
                statusItem = existing
            } else {
                let newItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                statusItems[menuItem.id] = newItem
                statusItem = newItem
            }

            configure(statusItem: statusItem, with: menuItem, store: store)
            // Map the button to the item ID for click handling
            if let button = statusItem.button {
                let ptr = Unmanaged.passUnretained(button).toOpaque()
                buttonItemMap[ptr] = menuItem.id
            }
        }

        // Remove the fallback item if it was created earlier
        removeFallbackItem()
    }

    // MARK: - Status Item Configuration

    private func configure(statusItem: NSStatusItem, with item: MenuBarItem, store: RemapStore) {
        if let button = statusItem.button {
            if !item.icon.isEmpty {
                button.image = NSImage(systemSymbolName: item.icon, accessibilityDescription: item.name)
            } else {
                button.image = NSImage(systemSymbolName: "circle", accessibilityDescription: item.name)
            }
            button.toolTip = item.name
        }

        // If the item has children, show a submenu
        // If it only has click actions, respond to clicks directly
        if !item.children.isEmpty {
            statusItem.menu = buildMenu(for: item, store: store)
            statusItem.button?.action = nil
            statusItem.button?.target = nil
        } else if item.leftClickAction?.kind != .none || item.rightClickAction?.kind != .none {
            // Direct click — no menu, just execute on click
            statusItem.menu = nil
            statusItem.button?.action = #selector(handleStatusItemClick(_:))
            statusItem.button?.target = self
        } else {
            // No actions — show an empty menu with just the name
            let menu = NSMenu()
            menu.addItem(withTitle: item.name, action: nil, keyEquivalent: "")
            statusItem.menu = menu
            statusItem.button?.action = nil
            statusItem.button?.target = nil
        }
    }

    /// Build a menu for a MenuBarItem that has children.
    private func buildMenu(for item: MenuBarItem, store: RemapStore) -> NSMenu {
        let menu = NSMenu(title: item.name)
        menu.addItem(withTitle: item.name, action: nil, keyEquivalent: "")

        if let left = item.leftClickAction, left.kind != .none {
            let actionItem = NSMenuItem(title: "Left Click: \(left.summary)", action: #selector(executeFromMenu(_:)), keyEquivalent: "")
            actionItem.representedObject = ItemActionPayload(id: item.id, useRight: false)
            actionItem.target = self
            menu.addItem(actionItem)
        }
        if let right = item.rightClickAction, right.kind != .none {
            let actionItem = NSMenuItem(title: "⌥ Click: \(right.summary)", action: #selector(executeFromMenu(_:)), keyEquivalent: "")
            actionItem.representedObject = ItemActionPayload(id: item.id, useRight: true)
            actionItem.target = self
            menu.addItem(actionItem)
        }

        if (!item.children.isEmpty) || (item.leftClickAction?.kind != .none || item.rightClickAction?.kind != .none) {
            menu.addItem(.separator())
        }

        for child in item.children where child.isEnabled {
            if child.isSeparator {
                menu.addItem(.separator())
            } else if !child.children.isEmpty {
                let submenu = NSMenu(title: child.name)
                for grandchild in child.children where grandchild.isEnabled {
                    let grandchildItem = NSMenuItem(title: grandchild.name, action: #selector(executeFromMenu(_:)), keyEquivalent: "")
                    grandchildItem.representedObject = ItemActionPayload(id: grandchild.id, useRight: false)
                    grandchildItem.target = self
                    if !grandchild.icon.isEmpty {
                        grandchildItem.image = NSImage(systemSymbolName: grandchild.icon, accessibilityDescription: grandchild.name)
                    }
                    submenu.addItem(grandchildItem)
                }
                let parentItem = NSMenuItem(title: child.name, action: nil, keyEquivalent: "")
                parentItem.submenu = submenu
                parentItem.image = NSImage(systemSymbolName: child.icon, accessibilityDescription: child.name)
                menu.addItem(parentItem)
            } else {
                let childItem = NSMenuItem(title: child.name, action: #selector(executeFromMenu(_:)), keyEquivalent: "")
                childItem.representedObject = ItemActionPayload(id: child.id, useRight: false)
                childItem.target = self
                if !child.icon.isEmpty {
                    childItem.image = NSImage(systemSymbolName: child.icon, accessibilityDescription: child.name)
                }
                menu.addItem(childItem)
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Show Breadboard", action: #selector(showBreadboard), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Fallback

    private var fallbackItemID: UUID?

    private func ensureFallbackItem() {
        if fallbackItemID != nil { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Breadboard")
        }
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Show Breadboard", action: #selector(showBreadboard), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        item.menu = menu
        let id = UUID()
        statusItems[id] = item
        fallbackItemID = id
    }

    private func removeFallbackItem() {
        guard let id = fallbackItemID, let item = statusItems[id] else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItems.removeValue(forKey: id)
        fallbackItemID = nil
    }

    // MARK: - Actions

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let ptr = Unmanaged.passUnretained(sender).toOpaque()
        guard let itemID = buttonItemMap[ptr],
              let store,
              let item = store.menuBarItems.first(where: { $0.id == itemID }) else { return }
        let useOption = NSEvent.modifierFlags.contains(.option)
        if useOption, let action = item.rightClickAction, action.kind != .none {
            store.executeMenuBarAction(action)
        } else if let action = item.leftClickAction, action.kind != .none {
            store.executeMenuBarAction(action)
        }
    }

    @objc private func executeFromMenu(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? ItemActionPayload,
              let store else { return }

        // Search all items (including nested children)
        func find(id: UUID, in items: [MenuBarItem]) -> MenuBarItem? {
            for item in items {
                if item.id == id { return item }
                if let found = find(id: id, in: item.children) { return found }
            }
            return nil
        }
        guard let targetItem = find(id: payload.id, in: store.menuBarItems) else { return }

        if payload.useRight, let action = targetItem.rightClickAction, action.kind != .none {
            store.executeMenuBarAction(action)
        } else if let action = targetItem.leftClickAction, action.kind != .none {
            store.executeMenuBarAction(action)
        }
    }

    @objc private func showBreadboard() {
        NSApp.activate(ignoringOtherApps: true)
        if let win = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            win.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Helper

private struct ItemActionPayload {
    let id: UUID
    let useRight: Bool
}

// MARK: - App

struct breadboardApp: App {
    @StateObject private var store = RemapStore()

    init() {
        StatusBarController.shared.install()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(store: store)
                .frame(minWidth: 1100, minHeight: 700)
                .frame(idealWidth: 1280, idealHeight: 800)
                .onAppear {
                    StatusBarController.shared.attach(store: store)
                }
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .onAppear {
                    StatusBarController.shared.attach(store: store)
                }
        }
    }
}
