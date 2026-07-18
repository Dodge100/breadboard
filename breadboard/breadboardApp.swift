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
            MenuBarCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct MenuBarCommands: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
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
