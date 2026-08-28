import AppKit

@MainActor
final class ClipboardMonitor {
    private let pasteboard: PasteboardReading
    private let repository: ClipboardRepositoryProtocol
    private let settings: AppSettings
    private let interval: TimeInterval
    private var timer: Timer?
    private(set) var knownChangeCount: Int
    var isRunning: Bool { timer != nil }

    init(pasteboard: PasteboardReading = NSPasteboard.general, repository: ClipboardRepositoryProtocol, settings: AppSettings, interval: TimeInterval = 0.5) {
        self.pasteboard = pasteboard
        self.repository = repository
        self.settings = settings
        self.interval = interval
        self.knownChangeCount = pasteboard.changeCount
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollNow()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pollNow() {
        let count = pasteboard.changeCount
        guard count != knownChangeCount else { return }
        knownChangeCount = count

        guard let value = pasteboard.string(forType: .string),
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        do {
            _ = try repository.recordCopiedText(value, historyLimit: settings.historyLimit)
        } catch {
            #if DEBUG
            NSLog("Clipboard persistence failed: %@", error.localizedDescription)
            #endif
        }
    }

    // App-generated clipboard writes must not be recorded as newly copied text.
    func acknowledgeCurrentChange() {
        knownChangeCount = pasteboard.changeCount
    }
}
