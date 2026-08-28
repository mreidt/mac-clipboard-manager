import Foundation
import SwiftData

@Model
final class ClipboardEntry {
    @Attribute(.unique) var id: UUID
    var text: String
    var copiedAt: Date
    var isFavorite: Bool
    var favoritedAt: Date?

    init(id: UUID = UUID(), text: String, copiedAt: Date = .now, isFavorite: Bool = false, favoritedAt: Date? = nil) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.isFavorite = isFavorite
        self.favoritedAt = favoritedAt
    }
}
