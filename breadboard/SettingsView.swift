import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Text("General settings coming soon.")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
        }
        .frame(width: 400, height: 250)
    }
}
