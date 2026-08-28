import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var container: ModelContainer!
    var settings: AppSettings!
    var repository: ClipboardRepository!
    var monitor: ClipboardMonitor!
    var picker: ClipboardPanelController!
    var loginItems: LoginItemManager!
    var shortcut: GlobalShortcutManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        do { container = try ModelContainer(for: ClipboardEntry.self) } catch { fatalError("Unable to load model container: \(error)") }
        settings = AppSettings(); repository = ClipboardRepository(context: container.mainContext); monitor = ClipboardMonitor(repository: repository, settings: settings); monitor.start()
        let model = ClipboardPickerViewModel(repository: repository); picker = ClipboardPanelController(model: model, settings: settings, monitor: monitor); let copyService = CopySelectionService(repository: repository, settings: settings, monitor: monitor); picker.onSelection = { [weak picker] entry in copyService.copy(entry); picker?.hide() }; picker.onSettings = { [weak self] in self?.picker.hide(); NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }
        loginItems = LoginItemManager(settings: settings); loginItems.reconcile(); shortcut = GlobalShortcutManager { [weak picker] in picker?.toggle() }; shortcut.start()
    }
}
