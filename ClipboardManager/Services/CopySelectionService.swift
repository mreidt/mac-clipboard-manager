import AppKit

@MainActor
final class CopySelectionService {
    let repository: ClipboardRepository
    let settings: AppSettings
    let monitor: ClipboardMonitor
    init(repository: ClipboardRepository, settings: AppSettings, monitor: ClipboardMonitor) { self.repository = repository; self.settings = settings; self.monitor = monitor }
    func copy(_ entry: ClipboardEntry) {
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(entry.text, forType: .string); monitor.acknowledgeCurrentChange()
        try? repository.markSelected(entryID: entry.id, moveToTop: settings.moveSelectedToTop)
        if settings.playCopySound { NSSound(named: NSSound.Name("Pop"))?.play() }
    }
}
