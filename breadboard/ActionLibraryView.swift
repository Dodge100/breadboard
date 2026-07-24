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

// MARK: - Condition Category

struct ConditionCategory: Identifiable {
    let id = UUID()
    let name: String
    let conditions: [ConditionKind]

    init(_ name: String, _ conditions: [ConditionKind]) {
        self.name = name
        self.conditions = conditions
    }
}

let conditionCategories: [ConditionCategory] = [
    ConditionCategory("App & Window", [
        .frontmostApp, .frontmostAppName, .runningCondition, .window
    ]),
    ConditionCategory("Input", [
        .inputSource, .device, .deviceExists, .keyboardType
    ]),
    ConditionCategory("Variables", [
        .variable, .globalVariable, .expression, .token
    ]),
    ConditionCategory("System", [
        .screen, .namedClipboard, .eventChanged, .pixelCondition
    ])
]

// MARK: - Action Library Panel

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
    @State private var collapsedCategories: Set<String> = []

    private static let mostUsed: [ActionKind] = [
        .sendKey, .sendText, .setVariable, .openApp, .activateApp,
        .runShell, .setNotification, .delay, .activateLastApp, .getClipboard
    ]

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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                TextField("Search actions…", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .font(.subheadline)
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
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            // List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if searchText.isEmpty {
                        sectionHeader("Most Used", isExpanded: .constant(true))
                            .padding(.top, 4)
                        ForEach(Self.mostUsed, id: \.self) { kind in
                            actionRow(kind)
                        }
                        separatorLine
                    }

                    ForEach(filteredCategories) { category in
                        sectionHeader(category.name, isExpanded: Binding(
                            get: { !collapsedCategories.contains(category.name) },
                            set: { if $0 { collapsedCategories.remove(category.name) } else { collapsedCategories.insert(category.name) } }
                        ))
                        if !collapsedCategories.contains(category.name) {
                            ForEach(category.actions, id: \.self) { kind in
                                actionRow(kind)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 240)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
        .overlay(
            Rectangle()
                .fill(.separator.opacity(0.3))
                .frame(width: 1),
            alignment: .leading
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: -4, y: 0)
        .onAppear {
            isSearchFocused = true
        }
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(.separator.opacity(0.15))
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Row

    private func actionRow(_ kind: ActionKind) -> some View {
        Button {
            onSelect(kind)
            withAnimation { isPresented = false }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: kind.symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(kind.rawValue)
                    .font(.subheadline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Condition Library Panel

struct ConditionLibraryPanel: View {
    @Binding var isPresented: Bool
    let onSelect: (ConditionKind) -> Void
    @State private var searchText = ""
    @State private var hoveredKind: ConditionKind?
    @FocusState private var isSearchFocused: Bool
    @State private var collapsedCategories: Set<String> = []

    private static let mostUsed: [ConditionKind] = [
        .frontmostApp, .inputSource, .variable, .deviceExists,
        .runningCondition, .window, .globalVariable
    ]

    private var filteredCategories: [ConditionCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return conditionCategories }
        return conditionCategories.compactMap { category in
            let matching = category.conditions.filter { kind in
                kind.rawValue.lowercased().contains(query)
            }
            guard !matching.isEmpty else { return nil }
            return ConditionCategory(category.name, matching)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Condition")
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                TextField("Search conditions…", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .font(.subheadline)
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
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            // List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if searchText.isEmpty {
                        sectionHeader("Most Used", isExpanded: .constant(true))
                            .padding(.top, 4)
                        ForEach(Self.mostUsed, id: \.self) { kind in
                            conditionRow(kind)
                        }
                        separatorLine
                    }

                    ForEach(filteredCategories) { category in
                        sectionHeader(category.name, isExpanded: Binding(
                            get: { !collapsedCategories.contains(category.name) },
                            set: { if $0 { collapsedCategories.remove(category.name) } else { collapsedCategories.insert(category.name) } }
                        ))
                        if !collapsedCategories.contains(category.name) {
                            ForEach(category.conditions, id: \.self) { kind in
                                conditionRow(kind)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 240)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
        .overlay(
            Rectangle()
                .fill(.separator.opacity(0.3))
                .frame(width: 1),
            alignment: .leading
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: -4, y: 0)
        .onAppear {
            isSearchFocused = true
        }
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(.separator.opacity(0.15))
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Condition Row

    private func conditionRow(_ kind: ConditionKind) -> some View {
        Button {
            onSelect(kind)
            withAnimation { isPresented = false }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: kind.symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(kind.rawValue)
                    .font(.subheadline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
