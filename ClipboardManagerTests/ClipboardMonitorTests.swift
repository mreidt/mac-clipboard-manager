import XCTest
import SwiftData
import AppKit
@testable import ClipboardManager

final class FakePasteboard: PasteboardReading { var changeCount = 0; var value: String?; func string(forType dataType: NSPasteboard.PasteboardType) -> String? { value } }

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    func testChangedTextIsRecordedAndBlankIgnored() throws { let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)); let repo = ClipboardRepository(context: container.mainContext); let settings = AppSettings(defaults: UserDefaults(suiteName: "monitor-\(UUID())")!); let fake = FakePasteboard(); let monitor = ClipboardMonitor(pasteboard: fake, repository: repo, settings: settings); fake.value = " exact\ntext "; fake.changeCount = 1; monitor.pollNow(); XCTAssertEqual(try repo.fetchRecent().first?.text, " exact\ntext "); fake.value = "  "; fake.changeCount = 2; monitor.pollNow(); XCTAssertEqual(try repo.fetchRecent().count, 1) }
}
