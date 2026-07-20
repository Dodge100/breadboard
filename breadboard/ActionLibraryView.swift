import SwiftUI

// MARK: - Action Library Category

struct ActionCategory: Identifiable {
    let id = UUID()
    let name: String
    let actions: [ActionKind]

    init(_ name: String, _ actions: [ActionKind]) {
        self.name = name
        self.actions = actions
    }
}

// MARK: - All Categories

let actionCategories: [ActionCategory] = [
    ActionCategory("Input", [
        .sendKey, .sendText, .consumerKey, .pointingButton, .mouseKey,
        .stickyModifier, .holdDown, .disable, .fromEvent
    ]),
    ActionCategory("Variables", [
        .setVariable, .unsetVariable, .toggleVariable,
        .incrementVariable, .decrementVariable,
        .setGlobalVariable, .unsetGlobalVariable
    ]),
    ActionCategory("Applications", [
        .openApp, .activateApp, .hideApp, .unhideApp,
        .quitApp, .forceQuitApp, .activateLastApp
    ]),
    ActionCategory("Windows", [
        .windowAction
    ]),
    ActionCategory("System", [
        .lockScreen, .showDesktop, .missionControl, .toggleDarkMode,
        .setVolume, .muteSystem, .emptyTrash, .getBatteryState,
        .getIPAddress, .toggleHiddenFiles, .logOut, .restartSystem,
        .shutdownSystem
    ]),
    ActionCategory("Text", [
        .speakText, .transformText, .calculateExpression
    ]),
    ActionCategory("Clipboard", [
        .setClipboard, .getClipboard, .clearClipboard,
        .appendClipboard, .pasteClipboard, .getSelectedText
    ]),
    ActionCategory("Automation", [
        .runShell, .runShortcut, .runAppleScript, .executeNamedTrigger,
        .sendUserCommand, .selectInputSource
    ]),
    ActionCategory("Files & Web", [
        .openFile, .openFolder, .openURL, .httpRequest
    ]),
    ActionCategory("Feedback", [
        .setNotification, .playSound, .flashScreen
    ]),
    ActionCategory("Control", [
        .delay, .halt, .showPalette, .hidePalette
    ])
]

// MARK: - Action Library Panel

struct ActionLibraryPanel: View {
    @Binding var isPresented: Bool
    let onSelect: (ActionKind) -> Void
    @State private var searchText = ""
    @State private var hoveredKind: ActionKind?
    @FocusState private var isSearchFocused: Bool

    private var filteredCategories: [ActionCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return actionCategories }
        return actionCategories.compactMap { category in
            let matching = category.actions.filter { kind in
                kind.rawValue.lowercased().contains(query)
            }
            guard !matching.isEmpty else { return nil }
            return ActionCategory(category.name, matching)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Action")
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

            Divider()

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                TextField("Search…", text: $searchText)
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
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Category list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredCategories) { category in
                        ForEach(category.actions, id: \.self) { kind in
                            actionRow(kind)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 240)
        .background(.background)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Action Row

    private func actionRow(_ kind: ActionKind) -> some View {
        let isHovered = hoveredKind == kind
        return Button {
            onSelect(kind)
            withAnimation { isPresented = false }
        } label: {
            Text(kind.rawValue)
                .font(.body)
                .foregroundStyle(isHovered ? Color.accentColor : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
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
