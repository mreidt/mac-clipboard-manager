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
}
