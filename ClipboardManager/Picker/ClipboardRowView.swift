import SwiftUI

struct ClipboardRowView: View {
    let entry: ClipboardEntry
    let index: Int
    let selected: Bool
    let onSelect: () -> Void
    let onFavorite: () -> Void

    private var preview: String {
        entry.text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(index < 10 ? "⌘\(index)" : "").font(.caption.monospaced()).frame(width: 34, alignment: .leading)
            Text(preview).lineLimit(1).truncationMode(.tail).frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onFavorite) { Image(systemName: entry.isFavorite ? "pin.fill" : "pin").foregroundStyle(entry.isFavorite ? .orange : .secondary) }
                .buttonStyle(.plain)
                .help(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                .accessibilityLabel(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites")
        }.frame(height: 54).padding(.horizontal, 12).background(selected ? Color.accentColor.opacity(0.18) : .clear).clipShape(RoundedRectangle(cornerRadius: 8)).contentShape(Rectangle()).onTapGesture(perform: onSelect).accessibilityElement(children: .combine).accessibilityLabel("\(preview), \(entry.isFavorite ? "favorite" : "not favorite")\(index < 10 ? ", shortcut Command \(index)" : "")").accessibilityAddTraits(selected ? .isSelected : [])
    }
}
