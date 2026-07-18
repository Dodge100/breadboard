import SwiftUI

struct ContentView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        RemapView(store: store)
    }
}

#Preview {
    ContentView(store: RemapStore())
}
