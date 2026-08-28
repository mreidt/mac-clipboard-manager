import SwiftUI
import SwiftData

struct ClipboardPickerView: View {
    @Bindable var model: ClipboardPickerViewModel
    @FocusState private var searchFocused: Bool
    let onSelect: (ClipboardEntry) -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Clipboard").font(.title3.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Picker("Clipboard section", selection: $model.activeTab) { ForEach(ClipboardTab.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            TextField("Search clipboard", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .onAppear { searchFocused = true }
                .onChange(of: model.focusSearchToken) { _, _ in searchFocused = true }
            ZStack {
                if model.filteredEntries.isEmpty {
                    Text(model.searchText.isEmpty ? (model.activeTab == .recent ? "No clipboard history yet" : "No favorites yet") : "No matching clipboard entries")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(model.filteredEntries.enumerated()), id: \.element.id) { index, entry in
                                    ClipboardRowView(entry: entry, index: index, selected: model.selectedIndex == index, onSelect: { onSelect(entry) }, onFavorite: { model.toggleFavorite(entry) }).id(entry.id)
                                }
                            }
                        }
                        .onChange(of: model.selectedIndex) { _, newValue in
                            if let i = newValue, model.filteredEntries.indices.contains(i) {
                                withAnimation { proxy.scrollTo(model.filteredEntries[i].id, anchor: .center) }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 54, maxHeight: 450)
            HStack { Text(model.entries.count == 1 ? "1 item" : "\(model.entries.count) items").foregroundStyle(.secondary); Spacer(); Button(action: onSettings) { Image(systemName: "gearshape").imageScale(.medium) }.buttonStyle(.plain).help("Open Settings").accessibilityLabel("Open Settings").accessibilityHint("Opens Clipboard Manager settings") }.font(.caption)
        }.padding(16).frame(width: 490, height: 500).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 16)).environment(\.controlActiveState, .active)
    }
}

#Preview("Recent – Light") {
    ClipboardPickerPreview.makeView()
}

#Preview("Recent – Dark") {
    ClipboardPickerPreview.makeView()
        .preferredColorScheme(.dark)
}

#Preview("Favorites") {
    ClipboardPickerPreview.makeView(favoritesOnly: true)
}

#Preview("No entries") {
    ClipboardPickerPreview.makeView(entries: [])
}

#Preview("No search results") {
    let view = ClipboardPickerPreview.makeView()
    view.model.searchText = "not found"
    return view
}

#Preview("Long multiline and Unicode") {
    ClipboardPickerPreview.makeView(entries: [
        "A very long clipboard entry with 日本語, emoji 🚀, and multiple lines\nthat should remain one compact row\nwithout changing the original value."
    ])
}

@MainActor
private enum ClipboardPickerPreview {
    static func makeView(entries: [String] = ["First copied item", "Another useful snippet"], favoritesOnly: Bool = false) -> ClipboardPickerView {
        let container = try! ModelContainer(for: ClipboardEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repository = ClipboardRepository(context: container.mainContext)
        for (index, text) in entries.enumerated() {
            let entry = try! repository.recordCopiedText(text, historyLimit: 20)!
            if favoritesOnly || (index == 0 && entries.count > 1) {
                try! repository.setFavorite(entryID: entry.id, isFavorite: true)
            }
        }
        let model = ClipboardPickerViewModel(repository: repository)
        model.prepareForOpening()
        if favoritesOnly { model.activeTab = .favorites }
        return ClipboardPickerView(model: model, onSelect: { _ in }, onSettings: {})
    }
}
