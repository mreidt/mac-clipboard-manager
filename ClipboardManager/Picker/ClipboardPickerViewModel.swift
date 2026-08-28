import Foundation
import Observation

enum ClipboardTab: String, CaseIterable { case recent = "Recent", favorites = "Favorites" }

enum ClipboardPickerKeyCommand: Equatable {
    case moveSelection(by: Int)
    case copySelected
    case close
    case focusSearch
    case copyVisible(index: Int)
}

@MainActor
@Observable
final class ClipboardPickerViewModel {
    let repository: ClipboardRepository
    var activeTab: ClipboardTab = .recent {
        didSet {
            reload()
            selectedIndex = filteredEntries.isEmpty ? nil : 0
        }
    }
    var searchText = "" { didSet { clampSelection() } }
    private(set) var entries: [ClipboardEntry] = []
    private(set) var filteredEntries: [ClipboardEntry] = []
    var selectedIndex: Int?
    var isPresented = false
    var focusSearchToken = 0

    init(repository: ClipboardRepository) { self.repository = repository }
    func prepareForOpening() {
        activeTab = .recent
        searchText = ""
        reload()
        selectedIndex = filteredEntries.isEmpty ? nil : 0
    }

    func reload() {
        do { entries = activeTab == .recent ? try repository.fetchRecent() : try repository.fetchFavorites() } catch { entries = [] }
        clampSelection()
    }

    func clampSelection() {
        let query = searchText.lowercased()
        filteredEntries = query.isEmpty ? entries : entries.filter { $0.text.lowercased().contains(query) }
        if filteredEntries.isEmpty { selectedIndex = nil } else if let selectedIndex { self.selectedIndex = min(max(0, selectedIndex), filteredEntries.count - 1) } else { selectedIndex = 0 }
    }

    func moveSelection(by offset: Int) { guard !filteredEntries.isEmpty else { return }; selectedIndex = min(max(0, (selectedIndex ?? 0) + offset), filteredEntries.count - 1) }
    func selectVisibleIndex(_ index: Int) { guard filteredEntries.indices.contains(index) else { return }; selectedIndex = index }
    func entry(at index: Int) -> ClipboardEntry? { filteredEntries.indices.contains(index) ? filteredEntries[index] : nil }
    func selectedEntry() -> ClipboardEntry? { selectedIndex.flatMap(entry(at:)) }
    func toggleFavorite(_ entry: ClipboardEntry) { try? repository.setFavorite(entryID: entry.id, isFavorite: !entry.isFavorite); reload() }
    func digitIndex(_ digit: Int) -> Int? { (0...9).contains(digit) ? digit : nil }

    func handle(_ command: ClipboardPickerKeyCommand) -> ClipboardEntry? {
        switch command {
        case let .moveSelection(by: offset):
            moveSelection(by: offset)
            return nil
        case .copySelected:
            return selectedEntry()
        case let .copyVisible(index):
            return entry(at: index)
        case .close, .focusSearch:
            return nil
        }
    }
}
