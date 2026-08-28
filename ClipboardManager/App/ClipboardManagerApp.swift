import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        MenuBarExtra(AppInfo.name, systemImage: "clipboard") {
            MenuBarView(
                showClipboard: { delegate.picker?.toggle() },
                showSettings: { delegate.showSettingsWindow() }
            )
        }
        Settings {
            if let delegate = Optional(delegate), delegate.settings != nil {
                SettingsView(settings: delegate.settings, repository: delegate.repository, loginItems: delegate.loginItems) {
                    delegate.picker.model.prepareForOpening()
                }
            }
        }
    }
}
