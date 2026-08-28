import SwiftUI

struct MenuBarView: View {
    let showClipboard: () -> Void
    let showSettings: () -> Void
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(AppInfo.name)
            .font(.headline)
        Divider()
        Button("Show Clipboard") { showClipboard() }.keyboardShortcut(" ", modifiers: [.control, .shift])
        Button("Settings…") {
            showSettings()
            openSettings()
        }
        Button("About \(AppInfo.name)") { showAbout() }
        Divider()
        Button("Quit \(AppInfo.name)") { NSApplication.shared.terminate(nil) }
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = AppInfo.name
        alert.informativeText = "Created by \(AppInfo.author)\nVersion \(AppInfo.version)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
