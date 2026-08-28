import AppKit

protocol SelectionSoundPlaying: AnyObject {
    func play()
}

final class StandardSelectionSoundPlayer: SelectionSoundPlaying {
    func play() {
        NSSound(named: NSSound.Name("Pop"))?.play()
    }
}

@MainActor
final class CopySelectionService {
    let repository: ClipboardRepository
    let settings: AppSettings
    let monitor: ClipboardMonitor
    private let soundPlayer: SelectionSoundPlaying
    private let pasteboard: PasteboardWriting

    init(repository: ClipboardRepository, settings: AppSettings, monitor: ClipboardMonitor, soundPlayer: SelectionSoundPlaying = StandardSelectionSoundPlayer(), pasteboard: PasteboardWriting = NSPasteboard.general) {
        self.repository = repository
        self.settings = settings
        self.monitor = monitor
        self.soundPlayer = soundPlayer
        self.pasteboard = pasteboard
    }

    func copy(_ entry: ClipboardEntry) {
        pasteboard.clearContents(); pasteboard.setString(entry.text, forType: .string); monitor.acknowledgeCurrentChange()
        try? repository.markSelected(entryID: entry.id, moveToTop: settings.moveSelectedToTop)
        if settings.playCopySound {
            soundPlayer.play()
        }
    }
}
