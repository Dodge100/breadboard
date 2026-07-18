import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        TabView {
            GeneralSettingsView(store: store)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            ConfigProfileManagerView(store: store)
                .tabItem {
                    Label("Profiles", systemImage: "square.on.square")
                }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings

private struct GeneralSettingsView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { false },
                    set: { _ in /* TODO: Implement launch at login */ }
                ))
                Toggle("Show in Menu Bar", isOn: Binding(
                    get: { true },
                    set: { _ in /* TODO: Implement menu bar visibility */ }
                ))
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
