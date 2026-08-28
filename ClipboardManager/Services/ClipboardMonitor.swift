import AppKit
import SwiftData

@MainActor
final class ClipboardMonitor {
    private let pasteboard: PasteboardReading
    private let repository: ClipboardRepository
    private let settings: AppSettings
    private let interval: TimeInterval
    private var timer: Timer?
    private(set) var knownChangeCount: Int

    init(pasteboard: PasteboardReading = NSPasteboard.general, repository: ClipboardRepository, settings: AppSettings, interval: TimeInterval = 0.5) {
        self.pasteboard = pasteboard; self.repository = repository; self.settings = settings; self.interval = interval; self.knownChangeCount = pasteboard.changeCount
    }
    func start() { guard timer == nil else { return }; timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in Task { @MainActor in self?.pollNow() } }; RunLoop.main.add(timer!, forMode: .common) }
    func stop() { timer?.invalidate(); timer = nil }
    func pollNow() {
        let count = pasteboard.changeCount
        guard count != knownChangeCount else { return }
        knownChangeCount = count
        guard let value = pasteboard.string(forType: .string), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            _ = try repository.recordCopiedText(value, historyLimit: settings.historyLimit)
        } catch {
            #if DEBUG
            NSLog("Clipboard persistence failed: %@", error.localizedDescription)
            #endif
        }
    }
    func acknowledgeCurrentChange() { knownChangeCount = pasteboard.changeCount }
}
