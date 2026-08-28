import SwiftUI

struct ClipboardPickerView: View {
    @Bindable var model: ClipboardPickerViewModel
    @FocusState private var searchFocused: Bool
    let onSelect: (ClipboardEntry) -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Clipboard").font(.title3.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $model.activeTab) { ForEach(ClipboardTab.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            TextField("Search clipboard", text: $model.searchText).textFieldStyle(.roundedBorder).focused($searchFocused).onChange(of: model.focusSearchToken) { _, _ in searchFocused = true }
            ScrollViewReader { proxy in ScrollView { LazyVStack(spacing: 2) { ForEach(Array(model.filteredEntries.enumerated()), id: \.element.id) { index, entry in ClipboardRowView(entry: entry, index: index, selected: model.selectedIndex == index, onSelect: { onSelect(entry) }, onFavorite: { model.toggleFavorite(entry) }).id(entry.id) } } }.onChange(of: model.selectedIndex) { _, newValue in if let i = newValue, model.filteredEntries.indices.contains(i) { withAnimation { proxy.scrollTo(model.filteredEntries[i].id, anchor: .center) } } } }
            if model.filteredEntries.isEmpty { Text(model.searchText.isEmpty ? (model.activeTab == .recent ? "No clipboard history yet" : "No favorites yet") : "No matching clipboard entries").foregroundStyle(.secondary).frame(maxHeight: .infinity) }
            HStack { Text(model.entries.count == 1 ? "1 item" : "\(model.entries.count) items").foregroundStyle(.secondary); Spacer(); Button(action: onSettings) { Image(systemName: "gearshape").imageScale(.medium) }.buttonStyle(.plain).help("Open Settings").accessibilityLabel("Open Settings") }.font(.caption)
        }.padding(16).frame(width: 490, height: 500).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 16)).environment(\.controlActiveState, .active)
    }
}
