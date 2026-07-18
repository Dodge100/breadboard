import SwiftUI

enum BreadboardTab: String, CaseIterable, Identifiable {
    case remaps = "Keyboard Remaps"
    case menuBar = "Menu Bar Items"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .remaps: return "keyboard"
        case .menuBar: return "menubar.rectangle"
        }
    }
}

struct ContentView: View {
    @ObservedObject var store: RemapStore
    @State private var selectedTab: BreadboardTab = .remaps

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BreadboardTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(tab.rawValue)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .remaps:
            RemapView(store: store)
        case .menuBar:
            MenuBarItemsView(store: store)
        }
    }
}

#Preview {
    ContentView(store: RemapStore())
}
