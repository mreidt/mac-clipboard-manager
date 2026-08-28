import XCTest
import SwiftData
@testable import ClipboardManager

@MainActor
final class RepositoryPersistenceTests: XCTestCase {
    private func makeRepository() throws -> (ClipboardRepository, ModelContainer) { let container = try ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)); return (ClipboardRepository(context: container.mainContext), container) }
    func testRecordsAndRejectsBlankText() throws { let fixture = try makeRepository(); let repo = fixture.0; XCTAssertNotNil(try repo.recordCopiedText(" hello ", historyLimit: 20)); XCTAssertNil(try repo.recordCopiedText(" \n", historyLimit: 20)); XCTAssertEqual(try repo.fetchRecent().count, 1) }
    func testExactDuplicatesOnly() throws { let fixture = try makeRepository(); let repo = fixture.0; _ = try repo.recordCopiedText("A", historyLimit: 20); _ = try repo.recordCopiedText("A", historyLimit: 20); _ = try repo.recordCopiedText("a", historyLimit: 20); _ = try repo.recordCopiedText("A ", historyLimit: 20); XCTAssertEqual(try repo.fetchRecent().count, 3) }
    func testFavoritesAndClear() throws { let fixture = try makeRepository(); let repo = fixture.0; let a = try XCTUnwrap(repo.recordCopiedText("a", historyLimit: 20)); _ = try repo.recordCopiedText("b", historyLimit: 20); try repo.setFavorite(entryID: a.id, isFavorite: true); XCTAssertEqual(try repo.fetchFavorites().count, 1); try repo.clearRecentHistoryKeepingFavorites(); XCTAssertEqual(try repo.fetchRecent().count, 1); XCTAssertEqual(try repo.fetchFavorites().count, 1) }
    func testLimitPreservesFavorites() throws { let fixture = try makeRepository(); let repo = fixture.0; let favorite = try XCTUnwrap(repo.recordCopiedText("favorite", historyLimit: 20)); try repo.setFavorite(entryID: favorite.id, isFavorite: true); for i in 0..<12 { _ = try repo.recordCopiedText("\(i)", historyLimit: 10) }; XCTAssertEqual(try repo.fetchFavorites().count, 1); XCTAssertEqual(try repo.fetchRecent().filter { !$0.isFavorite }.count, 10) }

    func testRecentIsNewestFirst() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        _ = try repo.recordCopiedText("older", historyLimit: 20)
        Thread.sleep(forTimeInterval: 0.01)
        _ = try repo.recordCopiedText("newer", historyLimit: 20)

        XCTAssertEqual(try repo.fetchRecent().map(\.text), ["newer", "older"])
    }

    func testFavoritesAreOrderedByPinDate() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let older = try XCTUnwrap(repo.recordCopiedText("older", historyLimit: 20))
        let newer = try XCTUnwrap(repo.recordCopiedText("newer", historyLimit: 20))
        try repo.setFavorite(entryID: older.id, isFavorite: true)
        Thread.sleep(forTimeInterval: 0.01)
        try repo.setFavorite(entryID: newer.id, isFavorite: true)

        XCTAssertEqual(try repo.fetchFavorites().map(\.text), ["newer", "older"])
    }

    func testRecopyingFavoriteDoesNotChangePinDate() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let entry = try XCTUnwrap(repo.recordCopiedText("favorite", historyLimit: 20))
        try repo.setFavorite(entryID: entry.id, isFavorite: true)
        let pinDate = try XCTUnwrap(entry.favoritedAt)
        Thread.sleep(forTimeInterval: 0.01)

        _ = try repo.recordCopiedText("favorite", historyLimit: 20)

        XCTAssertEqual(entry.favoritedAt, pinDate)
        XCTAssertTrue(entry.copiedAt > pinDate)
    }

    func testLimitEnforcementDeletesOldestNonFavorites() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        for value in ["one", "two", "three"] {
            _ = try repo.recordCopiedText(value, historyLimit: 100)
            Thread.sleep(forTimeInterval: 0.01)
        }

        try repo.enforceHistoryLimit(10)

        XCTAssertEqual(try repo.fetchRecent().map(\.text), ["three", "two", "one"])
        // A clamped limit of 10 does not delete three entries; verify deletion at a larger fixture size.
        for value in 4...11 {
            _ = try repo.recordCopiedText("item-\(value)", historyLimit: 100)
            Thread.sleep(forTimeInterval: 0.001)
        }
        try repo.enforceHistoryLimit(10)
        XCTAssertFalse(try repo.fetchRecent().contains { $0.text == "one" })
    }

    func testMarkSelectedMovesOnlyCopiedDate() throws {
        let fixture = try makeRepository()
        let repo = fixture.0
        let entry = try XCTUnwrap(repo.recordCopiedText("selected", historyLimit: 20))
        try repo.setFavorite(entryID: entry.id, isFavorite: true)
        let originalFavoriteDate = entry.favoritedAt
        let originalCopiedDate = entry.copiedAt
        Thread.sleep(forTimeInterval: 0.01)

        try repo.markSelected(entryID: entry.id, moveToTop: true)

        XCTAssertTrue(entry.copiedAt > originalCopiedDate)
        XCTAssertEqual(entry.favoritedAt, originalFavoriteDate)
    }
}
