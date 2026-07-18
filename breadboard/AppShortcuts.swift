import AppIntents

@available(macOS 13.0, *)
struct OpenKeyEditorIntent: AppIntent {
    static var title: LocalizedStringResource = "Open KeyCommand"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(macOS 13.0, *)
struct BreadboardAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenKeyEditorIntent(),
            phrases: ["Open \(.applicationName)"],
            shortTitle: "Open KeyCommand",
            systemImageName: "keyboard"
        )
    }
}
