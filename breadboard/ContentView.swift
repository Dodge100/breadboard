import SwiftUI

// MARK: - Navigation Modes (PearCleaner-style)

enum AppMode: String, CaseIterable, Identifiable {
    case remaps = "Keyboard Remaps"
    case menuBar = "Menu Bar Items"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .remaps: return "keyboard"
        case .menuBar: return "menubar.rectangle"
        }
    }

    var title: String { rawValue }
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var store: RemapStore
    @State private var selectedMode: AppMode = .remaps

    var body: some View {
        VStack(spacing: 0) {
            switch selectedMode {
            case .remaps:
                RemapView(store: store)
            case .menuBar:
                MenuBarItemsView(store: store)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            // PearCleaner-style mode switcher: segmented control in the toolbar
            ToolbarItem(placement: .navigation) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(AppMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help("Switch between remap editor and menu bar items")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView(store: RemapStore())
}
