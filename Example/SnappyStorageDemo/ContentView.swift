import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SyncDemoView()
                .tabItem { Label("Sync", systemImage: "square.and.arrow.down") }
            CombineDemoView()
                .tabItem { Label("Combine", systemImage: "waveform.path.ecg") }
            AsyncDemoView()
                .tabItem { Label("Async", systemImage: "arrow.clockwise") }
            EncryptionDemoView()
                .tabItem { Label("Encryption", systemImage: "lock.shield") }
        }
    }
}
