import SwiftUI

// MARK: - Action Library Category

struct ActionCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let actions: [ActionKind]

    init(_ name: String, icon: String, _ actions: [ActionKind]) {
        self.name = name
        self.icon = icon
        self.actions = actions
    }
}

// MARK: - Action Descriptions

extension ActionKind {
    var description: String {
        switch self {
        // Input
        case .sendKey: return "Type a key combination on the keyboard"
        case .sendText: return "Type a string of text"
        case .consumerKey: return "Press a media/browser key (play, volume, etc.)"
        case .pointingButton: return "Press a mouse button"
        case .mouseKey: return "Move or click the mouse programmatically"
        case .stickyModifier: return "Toggle a modifier key on or off"
        case .holdDown: return "Hold a key down for a duration"
        case .disable: return "Prevent a key from being sent"
        case .fromEvent: return "Mirror or remap another input event"
        // Variables
        case .setVariable: return "Store a value in a named variable"
        case .unsetVariable: return "Delete a named variable"
        case .toggleVariable: return "Toggle a variable between true and false"
        case .setGlobalVariable: return "Store a value in a global variable"
        case .unsetGlobalVariable: return "Delete a global variable"
        case .incrementVariable: return "Add 1 to a variable's value"
        case .decrementVariable: return "Subtract 1 from a variable's value"
        // Apps
        case .openApp: return "Launch an application"
        case .activateApp: return "Bring an application to the foreground"
        case .hideApp: return "Hide a running application"
        case .unhideApp: return "Unhide a hidden application"
        case .quitApp: return "Quit an application gracefully"
        case .forceQuitApp: return "Force-quit an application"
        case .activateLastApp: return "Switch to the previously active app"
        // Windows
        case .windowAction: return "Arrange windows in preset layouts"
        // System
        case .lockScreen: return "Lock the Mac"
        case .showDesktop: return "Show the desktop"
        case .missionControl: return "Open Mission Control"
        case .toggleDarkMode: return "Toggle between light and dark mode"
        case .setVolume: return "Set the system volume level"
        case .muteSystem: return "Toggle system mute"
        case .emptyTrash: return "Empty the Trash"
        case .getBatteryState: return "Get current battery percentage and charging state"
        case .getIPAddress: return "Get the current IP address"
        case .toggleHiddenFiles: return "Show or hide hidden files in Finder"
        case .logOut: return "Log out of macOS"
        case .restartSystem: return "Restart the Mac"
        case .shutdownSystem: return "Shut down the Mac"
        // Text
        case .speakText: return "Speak text using text-to-speech"
        case .transformText: return "Change text case, trim, or replace"
        case .calculateExpression: return "Evaluate a math expression"
        // Clipboard
        case .setClipboard: return "Copy text to the clipboard"
        case .getClipboard: return "Read text from the clipboard"
        case .clearClipboard: return "Clear the clipboard"
        case .appendClipboard: return "Append text to the clipboard"
        case .pasteClipboard: return "Paste the clipboard contents"
        case .getSelectedText: return "Get the currently selected text"
        // Automation
        case .runShell: return "Execute a shell command in Terminal"
        case .runShortcut: return "Run a macOS Shortcut"
        case .runAppleScript: return "Execute an AppleScript"
        case .executeNamedTrigger: return "Trigger another named action"
        case .sendUserCommand: return "Send a user-defined command"
        case .selectInputSource: return "Switch the keyboard input source"
        // Web & Files
        case .openURL: return "Open a URL in the default browser"
        case .openFile: return "Open a file with its default app"
        case .openFolder: return "Open a folder in Finder"
        case .httpRequest: return "Make an HTTP request to a URL"
        // Feedback
        case .setNotification: return "Display a system notification"
        case .playSound: return "Play a sound effect"
        case .flashScreen: return "Flash the screen for visual feedback"
        // Control
        case .delay: return "Wait before running the next action"
        case .halt: return "Stop executing further actions"
        case .showPalette: return "Show the floating macro palette"
        case .hidePalette: return "Hide the floating macro palette"
        case .softwareFunction: return "Trigger a software function (click, etc.)"
        }
    }
}

// MARK: - All Categories

let actionCategories: [ActionCategory] = [
    ActionCategory("Input", icon: "keyboard", [
        .sendKey, .sendText, .consumerKey, .pointingButton, .mouseKey,
        .stickyModifier, .holdDown, .disable, .fromEvent
    ]),
    ActionCategory("Variables", icon: "equal.square", [
        .setVariable, .unsetVariable, .toggleVariable,
        .incrementVariable, .decrementVariable,
        .setGlobalVariable, .unsetGlobalVariable
    ]),
    ActionCategory("Applications", icon: "app", [
        .openApp, .activateApp, .hideApp, .unhideApp,
        .quitApp, .forceQuitApp, .activateLastApp
    ]),
    ActionCategory("Windows", icon: "macwindow", [
        .windowAction
    ]),
    ActionCategory("System", icon: "gearshape", [
        .lockScreen, .showDesktop, .missionControl, .toggleDarkMode,
        .setVolume, .muteSystem, .emptyTrash, .getBatteryState,
        .getIPAddress, .toggleHiddenFiles, .logOut, .restartSystem,
        .shutdownSystem
    ]),
    ActionCategory("Text", icon: "textformat", [
        .speakText, .transformText, .calculateExpression
    ]),
    ActionCategory("Clipboard", icon: "doc.on.clipboard", [
        .setClipboard, .getClipboard, .clearClipboard,
        .appendClipboard, .pasteClipboard, .getSelectedText
    ]),
    ActionCategory("Automation", icon: "bolt.fill", [
        .runShell, .runShortcut, .runAppleScript, .executeNamedTrigger,
        .sendUserCommand, .selectInputSource
    ]),
    ActionCategory("Files & Web", icon: "folder", [
        .openFile, .openFolder, .openURL, .httpRequest
    ]),
    ActionCategory("Feedback", icon: "speaker.wave.2", [
        .setNotification, .playSound, .flashScreen
    ]),
    ActionCategory("Control", icon: "flowcontrol", [
        .delay, .halt, .showPalette, .hidePalette
    ])
]

// MARK: - Action Library Panel

struct ActionLibraryPanel: View {
    @Binding var isPresented: Bool
    let onSelect: (ActionKind) -> Void
    @State private var searchText = ""
    @State private var expandedCategories: Set<String>
    @State private var hoveredKind: ActionKind?
    @FocusState private var isSearchFocused: Bool

    init(isPresented: Binding<Bool>, onSelect: @escaping (ActionKind) -> Void) {
        self._isPresented = isPresented
        self.onSelect = onSelect
        self._expandedCategories = State(initialValue: Set(actionCategories.map(\.name)))
    }

    private var filteredCategories: [ActionCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return actionCategories }
        return actionCategories.compactMap { category in
            let matching = category.actions.filter { kind in
                kind.rawValue.lowercased().contains(query)
                    || kind.description.lowercased().contains(query)
            }
            guard !matching.isEmpty else { return nil }
            return ActionCategory(category.name, icon: category.icon, matching)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            Divider()
            categoryList
        }
        .frame(width: 300)
        .background(.background)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label("Action Library", systemImage: "plus.circle")
                .font(.headline)
            Spacer()
            Button {
                withAnimation { isPresented = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
                .font(.caption)
            TextField("Search actions…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isSearchFocused)
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
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Category List

    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredCategories) { category in
                    categorySection(category)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func categorySection(_ category: ActionCategory) -> some View {
        let isExpanded = expandedCategories.contains(category.name)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedCategories.remove(category.name)
                    } else {
                        expandedCategories.insert(category.name)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(category.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(category.actions.count)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.quaternary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(category.actions, id: \.self) { kind in
                    actionRow(kind)
                }
            }
        }
    }

    // MARK: - Action Row

    private func actionRow(_ kind: ActionKind) -> some View {
        let isHovered = hoveredKind == kind
        return Button {
            onSelect(kind)
            withAnimation { isPresented = false }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: kind.symbol)
                    .font(.body)
                    .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                    .frame(width: 20, alignment: .center)

                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.rawValue)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(kind.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(isHovered ? Color.accentColor : .clear)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredKind = hovering ? kind : nil
            }
        }
    }
}
