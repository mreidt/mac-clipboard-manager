import XCTest
@testable import ClipboardManager

@MainActor
final class AppSettingsTests: XCTestCase {
    func testDefaultsAndClamping() { let suite = UserDefaults(suiteName: "ClipboardManagerTests-\(UUID())")!; let settings = AppSettings(defaults: suite); XCTAssertEqual(settings.historyLimit, 20); XCTAssertTrue(settings.moveSelectedToTop); settings.historyLimit = 1; XCTAssertEqual(settings.historyLimit, 10); settings.historyLimit = 101; XCTAssertEqual(settings.historyLimit, 100) }
    func testPersistence() { let suite = UserDefaults(suiteName: "ClipboardManagerTests-\(UUID())")!; let first = AppSettings(defaults: suite); first.historyLimit = 45; first.playCopySound = true; let second = AppSettings(defaults: suite); XCTAssertEqual(second.historyLimit, 45); XCTAssertTrue(second.playCopySound) }
}
