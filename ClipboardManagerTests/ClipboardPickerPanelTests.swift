import AppKit
import SwiftData
import XCTest
@testable import ClipboardManager

@MainActor
final class ClipboardPickerPanelTests: XCTestCase {
    func testArrowKeyWithHardwareModifierFlagsMovesSelection() throws {
        let panel = makePanel()
        var receivedCommand: ClipboardPickerKeyCommand?
        panel.onKeyCommand = { receivedCommand = $0 }
        let event = try makeKeyEvent(
            keyCode: 125,
            modifiers: [.numericPad, .function]
        )

        panel.sendEvent(event)

        XCTAssertEqual(receivedCommand, .moveSelection(by: 1))
    }

    func testReturnKeyRequestsCopyOfSelectedEntry() throws {
        let panel = makePanel()
        var receivedCommand: ClipboardPickerKeyCommand?
        panel.onKeyCommand = { receivedCommand = $0 }
        let event = try makeKeyEvent(keyCode: 36)

        panel.sendEvent(event)

        XCTAssertEqual(receivedCommand, .copySelected)
    }

    func testShowingPanelDoesNotReclaimFocusWhenApplicationStaysInactive() async throws {
        _ = NSApplication.shared
        let container = try ModelContainer(
            for: ClipboardEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = ClipboardRepository(context: container.mainContext)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "picker-panel-\(UUID())"))
        let settings = AppSettings(defaults: defaults)
        let monitor = ClipboardMonitor(repository: repository, settings: settings)
        let model = ClipboardPickerViewModel(repository: repository)
        let controller = ClipboardPanelController(
            model: model,
            settings: settings,
            monitor: monitor,
            targetSystem: NoFrontmostApplicationSystem()
        )

        controller.show()
        let mainQueueTurn = expectation(description: "next main queue turn")
        DispatchQueue.main.async { mainQueueTurn.fulfill() }
        await fulfillment(of: [mainQueueTurn], timeout: 1)

        XCTAssertFalse(NSApp.isActive)
        XCTAssertTrue(model.isPresented)
        XCTAssertEqual(model.focusSearchToken, 1)
        controller.hide()
    }

    private func makePanel() -> ClipboardPickerPanel {
        _ = NSApplication.shared
        return ClipboardPickerPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }

    private func makeKeyEvent(
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags = []
    ) throws -> NSEvent {
        try XCTUnwrap(
            NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: modifiers,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                characters: "",
                charactersIgnoringModifiers: "",
                isARepeat: false,
                keyCode: keyCode
            )
        )
    }
}

@MainActor
private final class NoFrontmostApplicationSystem: PasteTargetSystem {
    func frontmostApplication() -> PasteTarget? { nil }
    func activate(_ target: PasteTarget) -> Bool { false }
    func isFrontmost(_ target: PasteTarget) -> Bool { false }
}
