import XCTest
import SwiftData
@testable import ClipboardManager

@MainActor
final class ClipboardPickerViewModelTests: XCTestCase {
    func testSearchAndDigitMapping() throws { let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)); let repo = ClipboardRepository(context: container.mainContext); _ = try repo.recordCopiedText("Hello World", historyLimit: 20); _ = try repo.recordCopiedText("Bonjour", historyLimit: 20); let vm = ClipboardPickerViewModel(repository: repo); vm.prepareForOpening(); vm.searchText = "WORLD"; XCTAssertEqual(vm.filteredEntries.first?.text, "Hello World"); XCTAssertEqual(vm.digitIndex(0), 0); XCTAssertEqual(vm.digitIndex(9), 9); XCTAssertNil(vm.digitIndex(10)) }
    func testSelectionClamps() throws { let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)); let repo = ClipboardRepository(context: container.mainContext); _ = try repo.recordCopiedText("one", historyLimit: 20); let vm = ClipboardPickerViewModel(repository: repo); vm.prepareForOpening(); vm.selectedIndex = 99; vm.searchText = "one"; XCTAssertEqual(vm.selectedIndex, 0) }
}
