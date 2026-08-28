import XCTest
import SwiftData
@testable import ClipboardManager

@MainActor
final class ClipboardPickerViewModelTests: XCTestCase {
    func testOpeningResetsToRecentAndSelectsFirstEntry() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("recent", historyLimit: 20)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.activeTab = .favorites
        vm.searchText = "stale"

        vm.prepareForOpening()

        XCTAssertEqual(vm.activeTab, .recent)
        XCTAssertEqual(vm.searchText, "")
        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.filteredEntries.map(\.text), ["recent"])
    }

    func testSearchIsCaseInsensitiveSubstringMatch() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("Hello World", historyLimit: 20)
        _ = try repo.recordCopiedText("Bonjour", historyLimit: 20)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()

        vm.searchText = "WORLD"

        XCTAssertEqual(vm.filteredEntries.map(\.text), ["Hello World"])
    }

    func testSearchAffectsOnlyTheActiveTab() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let recent = try XCTUnwrap(repo.recordCopiedText("recent match", historyLimit: 20))
        let favorite = try XCTUnwrap(repo.recordCopiedText("favorite match", historyLimit: 20))
        try repo.setFavorite(entryID: favorite.id, isFavorite: true)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()
        vm.searchText = "match"

        XCTAssertEqual(vm.filteredEntries.map(\.text).sorted(), ["favorite match", "recent match"])
        vm.activeTab = .favorites
        XCTAssertEqual(vm.filteredEntries.map(\.text), [favorite.text])
        XCTAssertEqual(recent.isFavorite, false)
    }

    func testTabChangeResetsSelectionToFirstFilteredResult() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("one", historyLimit: 20)
        let favorite = try XCTUnwrap(repo.recordCopiedText("two", historyLimit: 20))
        try repo.setFavorite(entryID: favorite.id, isFavorite: true)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()
        vm.selectedIndex = 1

        vm.activeTab = .favorites

        XCTAssertEqual(vm.selectedIndex, 0)
        XCTAssertEqual(vm.entry(at: 0)?.text, "two")
    }

    func testFilteringClampsSelectionAndEmptyResultsHaveNoSelection() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("one", historyLimit: 20)
        _ = try repo.recordCopiedText("two", historyLimit: 20)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()
        vm.selectedIndex = 99
        vm.searchText = "two"
        XCTAssertEqual(vm.selectedIndex, 0)

        vm.searchText = "missing"
        XCTAssertNil(vm.selectedIndex)
        XCTAssertTrue(vm.filteredEntries.isEmpty)
    }

    func testPinningRefreshesResultsWithoutChangingText() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let entry = try XCTUnwrap(repo.recordCopiedText("keep exact\ntext", historyLimit: 20))
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()

        vm.toggleFavorite(entry)

        XCTAssertEqual(vm.searchText, "")
        XCTAssertEqual(vm.activeTab, .recent)
        XCTAssertEqual(vm.entry(at: 0)?.text, "keep exact\ntext")
        XCTAssertTrue(try repo.fetchFavorites().contains { $0.text == "keep exact\ntext" })
    }

    func testDigitToIndexMapsZeroThroughNineDirectly() {
        let fixture = try! makeRepository()
        let vm = ClipboardPickerViewModel(repository: fixture.0)
        for digit in 0...9 { XCTAssertEqual(vm.digitIndex(digit), digit) }
        XCTAssertNil(vm.digitIndex(-1))
        XCTAssertNil(vm.digitIndex(10))
    }

    func testArrowSelectionStopsAtBothEnds() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("one", historyLimit: 20)
        _ = try repo.recordCopiedText("two", historyLimit: 20)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()

        _ = vm.handle(.moveSelection(by: -1))
        XCTAssertEqual(vm.selectedIndex, 0)
        _ = vm.handle(.moveSelection(by: 1))
        _ = vm.handle(.moveSelection(by: 1))
        XCTAssertEqual(vm.selectedIndex, 1)
    }

    func testMissingVisibleIndexDoesNothing() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("only entry", historyLimit: 20)
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()

        XCTAssertNil(vm.handle(.copyVisible(index: 9)))
        XCTAssertEqual(vm.selectedIndex, 0)
    }

    func testCopyCommandUsesFilteredEntry() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("first", historyLimit: 20)
        let matching = try XCTUnwrap(repo.recordCopiedText("matching second", historyLimit: 20))
        let vm = ClipboardPickerViewModel(repository: repo)
        vm.prepareForOpening()
        vm.searchText = "matching"

        XCTAssertEqual(vm.handle(.copyVisible(index: 0))?.id, matching.id)
        XCTAssertEqual(vm.handle(.copySelected)?.id, matching.id)
    }

    func testSelectionDateBehaviorRespectsMoveToTopAndKeepsFavoriteDate() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let entry = try XCTUnwrap(repo.recordCopiedText("selected", historyLimit: 20))
        try repo.setFavorite(entryID: entry.id, isFavorite: true)
        let favoriteDate = entry.favoritedAt
        let copiedDate = entry.copiedAt

        try repo.markSelected(entryID: entry.id, moveToTop: false)
        XCTAssertEqual(entry.copiedAt, copiedDate)
        XCTAssertEqual(entry.favoritedAt, favoriteDate)

        try repo.markSelected(entryID: entry.id, moveToTop: true)
        XCTAssertGreaterThan(entry.copiedAt, copiedDate)
        XCTAssertEqual(entry.favoritedAt, favoriteDate)
    }

    private func makeRepository() throws -> (ClipboardRepository, ModelContainer) {
        let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return (ClipboardRepository(context: container.mainContext), container)
    }
}
