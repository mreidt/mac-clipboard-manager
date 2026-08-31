import AppKit
import SwiftData
import XCTest
@testable import ClipboardManager

@MainActor
final class AutomaticPasteCoordinatorTests: XCTestCase {
    func testTrustedSelectionCopiesClosesRestoresFocusAndSendsOnePaste() async throws {
        let fixture = try makeFixture(trusted: true)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("line one\n🚀", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)

        await coordinator.selectAndPaste(entry, target: fixture.target)

        XCTAssertEqual(fixture.pasteboard.value, entry.text)
        XCTAssertEqual(fixture.events.values, ["copy", "close", "activate", "wait", "paste"])
        XCTAssertEqual(fixture.sender.sendCount, 1)
    }

    func testCopyHappensBeforeCloseAndActivation() async throws {
        let fixture = try makeFixture(trusted: true)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("value", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)

        await coordinator.selectAndPaste(entry, target: fixture.target)

        XCTAssertLessThan(fixture.events.values.firstIndex(of: "copy")!, fixture.events.values.firstIndex(of: "activate")!)
        XCTAssertLessThan(fixture.events.values.firstIndex(of: "close")!, fixture.events.values.firstIndex(of: "activate")!)
    }

    func testMissingPermissionCopiesClosesPromptsOnceAndDoesNotPaste() async throws {
        let fixture = try makeFixture(trusted: false)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("copy only", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)

        await coordinator.selectAndPaste(entry, target: fixture.target)
        await coordinator.selectAndPaste(entry, target: fixture.target)

        XCTAssertEqual(fixture.pasteboard.value, entry.text)
        XCTAssertEqual(fixture.permission.promptCount, 1)
        XCTAssertEqual(fixture.sender.sendCount, 0)
        XCTAssertFalse(fixture.events.values.contains("activate"))
    }

    func testLaterSelectionRechecksPermissionAndCanPaste() async throws {
        let fixture = try makeFixture(trusted: false)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("retry", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)

        await coordinator.selectAndPaste(entry, target: fixture.target)
        fixture.permission.trusted = true
        await coordinator.selectAndPaste(entry, target: fixture.target)

        XCTAssertEqual(fixture.sender.sendCount, 1)
        XCTAssertEqual(fixture.permission.checkCount, 2)
    }

    func testMissingOrTerminatedTargetDoesNotPaste() async throws {
        let fixture = try makeFixture(trusted: true)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("safe", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)
        fixture.target.isTerminated = true

        await coordinator.selectAndPaste(entry, target: fixture.target)

        XCTAssertEqual(fixture.pasteboard.value, entry.text)
        XCTAssertEqual(fixture.sender.sendCount, 0)
        XCTAssertFalse(fixture.events.values.contains("activate"))
    }

    func testRapidSelectionsAllowAtMostOnePaste() async throws {
        let fixture = try makeFixture(trusted: true)
        let entry = try XCTUnwrap(fixture.repository.recordCopiedText("once", historyLimit: 20))
        let coordinator = makeCoordinator(fixture)

        async let first: Void = coordinator.selectAndPaste(entry, target: fixture.target)
        async let second: Void = coordinator.selectAndPaste(entry, target: fixture.target)
        _ = await (first, second)

        XCTAssertEqual(fixture.sender.sendCount, 1)
    }

    private func makeCoordinator(_ fixture: Fixture) -> AutomaticPasteCoordinator {
        AutomaticPasteCoordinator(
            repository: fixture.repository,
            settings: fixture.settings,
            monitor: fixture.monitor,
            pasteboard: fixture.pasteboard,
            permission: fixture.permission,
            targetSystem: fixture.system,
            focusRestorer: fixture.restorer,
            keySender: fixture.sender,
            closePicker: { fixture.events.append("close") }
        )
    }

    private func makeFixture(trusted: Bool) throws -> Fixture {
        let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = TestRepository(context: container.mainContext)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "automatic-paste-\(UUID())")!)
        let events = EventLog()
        let pasteboard = TestPasteboard(events: events)
        let monitor = ClipboardMonitor(pasteboard: pasteboard, repository: repository, settings: settings)
        let target = TestTarget()
        let system = TestTargetSystem(target: target, events: events)
        let permission = TestPermission(trusted: trusted)
        let sender = TestKeySender(events: events)
        let restorer = TestFocusRestorer(events: events)
        return Fixture(container: container, repository: repository, settings: settings, pasteboard: pasteboard, monitor: monitor, events: events, target: target, system: system, permission: permission, sender: sender, restorer: restorer)
    }
}

@MainActor
private struct Fixture {
    let container: ModelContainer
    let repository: TestRepository
    let settings: AppSettings
    let pasteboard: TestPasteboard
    let monitor: ClipboardMonitor
    let events: EventLog
    let target: TestTarget
    let system: TestTargetSystem
    let permission: TestPermission
    let sender: TestKeySender
    let restorer: TestFocusRestorer
}

@MainActor
private final class EventLog {
    var values: [String] = []
    func append(_ value: String) { values.append(value) }
}

private final class TestTarget: PasteTarget {
    let processIdentifier: pid_t = 12345
    var isTerminated = false
}

@MainActor
private final class TestTargetSystem: PasteTargetSystem {
    let target: TestTarget
    let events: EventLog
    init(target: TestTarget, events: EventLog) { self.target = target; self.events = events }
    func frontmostApplication() -> PasteTarget? { target }
    func activate(_ target: PasteTarget) -> Bool { events.append("activate"); return true }
    func isFrontmost(_ target: PasteTarget) -> Bool { true }
}

@MainActor
private final class TestFocusRestorer: PasteFocusRestoring {
    let events: EventLog
    init(events: EventLog) { self.events = events }
    func waitUntilFrontmost(_ target: PasteTarget) async -> Bool { events.append("wait"); await Task.yield(); return true }
}

@MainActor
private final class TestPermission: AccessibilityPermissionChecking {
    var trusted: Bool
    var checkCount = 0
    var promptCount = 0
    init(trusted: Bool) { self.trusted = trusted }
    func isTrusted() -> Bool { checkCount += 1; return trusted }
    func requestPermissionPromptIfNeeded() {
        guard promptCount == 0 else { return }
        promptCount += 1
    }
}

@MainActor
private final class TestKeySender: PasteKeyEventSending {
    let events: EventLog
    var sendCount = 0
    init(events: EventLog) { self.events = events }
    func sendCommandV() -> Bool { sendCount += 1; events.append("paste"); return true }
}

@MainActor
private final class TestPasteboard: PasteboardReading, PasteboardWriting {
    let events: EventLog
    var changeCount = 0
    var value: String?
    init(events: EventLog) { self.events = events }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String? { value }
    func clearContents() -> Int { changeCount += 1; value = nil; events.append("copy"); return changeCount }
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool { changeCount += 1; value = string; return true }
}

@MainActor
private final class TestRepository: ClipboardRepositoryProtocol {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }
    @discardableResult func recordCopiedText(_ text: String, historyLimit: Int) throws -> ClipboardEntry? {
        let entry = ClipboardEntry(text: text)
        context.insert(entry)
        try context.save()
        return entry
    }
    func enforceHistoryLimit(_ limit: Int) throws {}
    func markSelected(entryID: UUID, moveToTop: Bool) throws {}
}
