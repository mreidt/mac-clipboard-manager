import SwiftUI

struct MenuBarView: View {
    let showClipboard: () -> Void
    let showSettings: () -> Void
    @State private var showingAbout = false

    var body: some View {
        Text(AppInfo.name)
            .font(.headline)
        Divider()
        Button("Show Clipboard") { showClipboard() }.keyboardShortcut(" ", modifiers: [.control, .shift])
        Button("Settings…") { showSettings() }
        Button("About (AppInfo.name)") { showingAbout = true }
        Divider()
        Button("Quit (AppInfo.name)") { NSApplication.shared.terminate(nil) }
            .alert(AppInfo.name, isPresented: $showingAbout) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Created by (AppInfo.author)\nVersion (AppInfo.version)")
            }
    }
}
