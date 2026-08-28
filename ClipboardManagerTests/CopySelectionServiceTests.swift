import AppKit
import SwiftData
import XCTest
@testable import ClipboardManager

@MainActor
final class CopySelectionServiceTests: XCTestCase {
    func testSelectionCopiesExactTextAndPlaysSoundOnceWhenEnabled() throws {
        let fixture = try makeFixture()
        fixture.settings.playCopySound = true
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("  line one\nline two  ", historyLimit: 20))
        let service = CopySelectionService(repository: fixture.repository, settings: fixture.settings, monitor: fixture.monitor, soundPlayer: fixture.sound, pasteboard: fixture.pasteboard)

        service.copy(entry)

        XCTAssertEqual(fixture.pasteboard.value, entry.text)
        XCTAssertEqual(fixture.sound.playCount, 1)
        XCTAssertEqual(fixture.repository.markSelectedCount, 1)
    }

    func testMonitoringDoesNotPlaySelectionSound() throws {
        let fixture = try makeFixture()
        fixture.settings.playCopySound = true
        fixture.pasteboard.value = "external copy"
        fixture.pasteboard.changeCount = 1

        fixture.monitor.pollNow()

        XCTAssertEqual(fixture.sound.playCount, 0)
        XCTAssertEqual(try fixture.repository.fetchRecent().map(\.text), ["external copy"])
    }

    func testDisabledSoundStillCopiesWithoutPlaying() throws {
        let fixture = try makeFixture()
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("copy me", historyLimit: 20))
        let service = CopySelectionService(repository: fixture.repository, settings: fixture.settings, monitor: fixture.monitor, soundPlayer: fixture.sound, pasteboard: fixture.pasteboard)

        service.copy(entry)

        XCTAssertEqual(fixture.pasteboard.value, "copy me")
        XCTAssertEqual(fixture.sound.playCount, 0)
    }

    private func makeFixture() throws -> (repository: SpyRepository, settings: AppSettings, monitor: ClipboardMonitor, pasteboard: FakePasteboardWriter, sound: SpySound, container: ModelContainer) {
        let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = SpyRepository(context: container.mainContext)
        let pasteboard = FakePasteboardWriter()
        let settings = AppSettings(defaults: UserDefaults(suiteName: "copy-selection-\(UUID())")!)
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository, settings: settings)
        return (repository, settings, monitor, pasteboard, SpySound(), container)
    }
}

@MainActor
private final class SpyRepository: ClipboardRepositoryProtocol {
    let context: ModelContext
    private(set) var markSelectedCount = 0

    init(context: ModelContext) { self.context = context }

    @discardableResult
    func recordCopiedText(_ text: String, historyLimit: Int) throws -> ClipboardEntry? {
        let entry = ClipboardEntry(text: text)
        context.insert(entry)
        try context.save()
        return entry
    }

    func enforceHistoryLimit(_ limit: Int) throws {}
    func markSelected(entryID: UUID, moveToTop: Bool) throws { markSelectedCount += 1 }
    func fetchRecent() throws -> [ClipboardEntry] { try context.fetch(FetchDescriptor<ClipboardEntry>()) }
}

@MainActor
private final class FakePasteboardWriter: PasteboardReading, PasteboardWriting {
    var changeCount = 0
    var value: String?
    func string(forType dataType: NSPasteboard.PasteboardType) -> String? { value }
    func clearContents() -> Int { changeCount += 1; value = nil; return changeCount }
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool { value = string; changeCount += 1; return true }
}

private final class SpySound: SelectionSoundPlaying {
    private(set) var playCount = 0
    func play() { playCount += 1 }
}
