import AppKit
import Observation
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var container: ModelContainer!
    var settings: AppSettings!
    var repository: ClipboardRepository!
    var monitor: ClipboardMonitor!
    var picker: ClipboardPanelController!
    var loginItems: LoginItemManager!
    var globalShortcut: GlobalShortcutManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        do { container = try ModelContainer(for: ClipboardEntry.self) } catch { fatalError("Unable to load model container: \(error)") }
        settings = AppSettings(); repository = ClipboardRepository(context: container.mainContext); monitor = ClipboardMonitor(repository: repository, settings: settings); monitor.start()
        observeHistoryLimitChanges()
        let model = ClipboardPickerViewModel(repository: repository); picker = ClipboardPanelController(model: model, settings: settings, monitor: monitor); let copyService = CopySelectionService(repository: repository, settings: settings, monitor: monitor); picker.onSelection = { [weak picker] entry in copyService.copy(entry); picker?.hide() }; picker.onSettings = { [weak self] in self?.picker.hide() }
        globalShortcut = GlobalShortcutManager(onToggle: { [weak self] in self?.picker.toggle() }); globalShortcut.start()
        loginItems = LoginItemManager(settings: settings); loginItems.reconcile()
    }

    private func observeHistoryLimitChanges() {
        withObservationTracking {
            _ = settings.historyLimit
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try self.repository.enforceHistoryLimit(self.settings.historyLimit)
                } catch {
                    #if DEBUG
                    NSLog("History-limit enforcement failed: %@", error.localizedDescription)
                    #endif
                }
                self.observeHistoryLimitChanges()
            }
        }
    }
}
