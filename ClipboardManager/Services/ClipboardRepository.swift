import Foundation
import SwiftData

@MainActor
final class ClipboardRepository {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }

    @discardableResult
    func recordCopiedText(_ text: String, historyLimit: Int) throws -> ClipboardEntry? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if let existing = try context.fetch(FetchDescriptor<ClipboardEntry>()).first(where: { $0.text == text }) { existing.copiedAt = .now; try enforceHistoryLimit(historyLimit); try context.save(); return existing }
        let entry = ClipboardEntry(text: text)
        context.insert(entry)
        try enforceHistoryLimit(historyLimit)
        try context.save()
        return entry
    }

    func fetchRecent() throws -> [ClipboardEntry] { try context.fetch(FetchDescriptor(sortBy: [SortDescriptor(\ClipboardEntry.copiedAt, order: .reverse)])) }
    func fetchFavorites() throws -> [ClipboardEntry] { try context.fetch(FetchDescriptor<ClipboardEntry>()).filter(\.isFavorite).sorted { ($0.favoritedAt ?? .distantPast) > ($1.favoritedAt ?? .distantPast) } }

    func setFavorite(entryID: UUID, isFavorite: Bool) throws {
        guard let entry = try entry(id: entryID) else { return }
        entry.isFavorite = isFavorite; entry.favoritedAt = isFavorite ? .now : nil; try context.save()
    }

    func markSelected(entryID: UUID, moveToTop: Bool) throws {
        guard moveToTop, let entry = try entry(id: entryID) else { return }
        entry.copiedAt = .now; try context.save()
    }

    func enforceHistoryLimit(_ limit: Int) throws {
        let clamped = max(10, min(100, limit))
        let nonFavorites = try context.fetch(FetchDescriptor<ClipboardEntry>()).filter { !$0.isFavorite }.sorted { $0.copiedAt > $1.copiedAt }
        for entry in nonFavorites.dropFirst(clamped) { context.delete(entry) }
        try context.save()
    }

    func clearRecentHistoryKeepingFavorites() throws {
        let entries = try context.fetch(FetchDescriptor<ClipboardEntry>()).filter { !$0.isFavorite }
        entries.forEach(context.delete); try context.save()
    }

    private func entry(id: UUID) throws -> ClipboardEntry? { try context.fetch(FetchDescriptor<ClipboardEntry>()).first { $0.id == id } }
}
