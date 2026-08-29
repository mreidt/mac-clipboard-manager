import XCTest
@testable import ClipboardManager

@MainActor
final class AccessibilityPermissionManagerTests: XCTestCase {
    func testPermissionPromptIsRequestedAtMostOnce() {
        var promptCount = 0
        let manager = AccessibilityPermissionManager(checkTrust: { false }, prompt: { promptCount += 1 })

        XCTAssertFalse(manager.isTrusted())
        manager.requestPermissionPromptIfNeeded()
        manager.requestPermissionPromptIfNeeded()

        XCTAssertEqual(promptCount, 1)
    }
}
