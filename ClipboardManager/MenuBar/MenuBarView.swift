import SwiftUI

struct MenuBarView: View {
    let showClipboard: () -> Void
    let showSettings: () -> Void
    var body: some View {
        Button("Show Clipboard") { showClipboard() }.keyboardShortcut(" ", modifiers: [.control, .shift])
        Button("Settings…") { showSettings() }
        Divider()
        Button("Quit Clipboard Manager") { NSApplication.shared.terminate(nil) }
    }
}
