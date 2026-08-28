import AppKit
import SwiftData
import XCTest
@testable import ClipboardManager

@MainActor
private final class FakePasteboard: PasteboardReading {
    var changeCount = 0
    var value: String?

    func string(forType dataType: NSPasteboard.PasteboardType) -> String? { value }
}

@MainActor
private final class SpyRepository: ClipboardRepositoryProtocol {
    var recordedTexts: [String] = []
    var error: Error?

    @discardableResult
    func recordCopiedText(_ text: String, historyLimit: Int) throws -> ClipboardEntry? {
        if let error { throw error }
        recordedTexts.append(text)
        return nil
    }

    func enforceHistoryLimit(_ limit: Int) throws {}
    func markSelected(entryID: UUID, moveToTop: Bool) throws {}
}

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    func testUnchangedChangeCountDoesNothing() {
        let fixture = makeFixture()
        fixture.monitor.pollNow()
        XCTAssertTrue(fixture.repository.recordedTexts.isEmpty)
    }

    func testChangedCountWithTextRecordsExactText() {
        let fixture = makeFixture()
        fixture.pasteboard.value = "  line one\nline two  "
        fixture.pasteboard.changeCount = 1

        fixture.monitor.pollNow()

        XCTAssertEqual(fixture.repository.recordedTexts, ["  line one\nline two  "])
    }

    func testChangedCountWithoutTextDoesNothing() {
        let fixture = makeFixture()
        fixture.pasteboard.changeCount = 1
        fixture.monitor.pollNow()
        XCTAssertTrue(fixture.repository.recordedTexts.isEmpty)
    }

    func testEmptyAndWhitespaceOnlyTextDoesNothing() {
        let fixture = makeFixture()

        for (count, value) in [(1, ""), (2, " \n\t ")] {
            fixture.pasteboard.value = value
            fixture.pasteboard.changeCount = count
            fixture.monitor.pollNow()
        }

        XCTAssertTrue(fixture.repository.recordedTexts.isEmpty)
    }

    func testRepeatedIdenticalTextProducesOnePersistedEntry() throws {
        let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = ClipboardRepository(context: container.mainContext)
        let pasteboard = FakePasteboard()
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository, settings: makeSettings())

        pasteboard.value = "same"
        pasteboard.changeCount = 1
        monitor.pollNow()
        pasteboard.changeCount = 2
        monitor.pollNow()

        XCTAssertEqual(try repository.fetchRecent().map(\.text), ["same"])
    }

    func testStartTwiceCreatesOnlyOneTimer() {
        let fixture = makeFixture(interval: 60)
        fixture.monitor.start()
        fixture.monitor.start()

        XCTAssertTrue(fixture.monitor.isRunning)
        fixture.monitor.stop()
    }

    func testStopPreventsLaterPolling() {
        let fixture = makeFixture(interval: 0.01)
        fixture.monitor.start()
        fixture.monitor.stop()
        fixture.pasteboard.value = "after stop"
        fixture.pasteboard.changeCount = 1

        RunLoop.main.run(until: Date().addingTimeInterval(0.03))

        XCTAssertTrue(fixture.repository.recordedTexts.isEmpty)
    }

    func testRepositoryErrorDoesNotDisableLaterPolls() {
        let fixture = makeFixture()
        fixture.repository.error = TestError.persistence
        fixture.pasteboard.value = "first"
        fixture.pasteboard.changeCount = 1
        fixture.monitor.pollNow()

        fixture.repository.error = nil
        fixture.pasteboard.value = "second"
        fixture.pasteboard.changeCount = 2
        fixture.monitor.pollNow()

        XCTAssertEqual(fixture.repository.recordedTexts, ["second"])
    }

    private func makeFixture(interval: TimeInterval = 0.5) -> (pasteboard: FakePasteboard, repository: SpyRepository, monitor: ClipboardMonitor) {
        let pasteboard = FakePasteboard()
        let repository = SpyRepository()
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository, settings: makeSettings(), interval: interval)
        return (pasteboard, repository, monitor)
    }

    private func makeSettings() -> AppSettings {
        AppSettings(defaults: UserDefaults(suiteName: "monitor-\(UUID())")!)
    }
}

private enum TestError: Error { case persistence }
