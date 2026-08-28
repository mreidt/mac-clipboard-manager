import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let repository: ClipboardRepository
    let loginItems: LoginItemManager
    @State private var clearConfirmation = false
    @State private var errorMessage: String?
    var body: some View {
        Form {
            Toggle("Launch at login", isOn: Binding(get: { loginItems.isEnabled }, set: { value in do { try loginItems.setEnabled(value) } catch { errorMessage = error.localizedDescription } }))
            Toggle("Play sound when copying", isOn: $settings.playCopySound)
            Stepper("Entries shown in picker: \(settings.historyLimit)", value: $settings.historyLimit, in: 10...100, step: 5)
            Text("Choose between 10 and 100 entries.").font(.caption).foregroundStyle(.secondary)
            HStack { Text("Global shortcut"); Spacer(); Text("⌃ ⇧ Space").font(.system(.body, design: .monospaced)).padding(5).background(.quaternary).clipShape(RoundedRectangle(cornerRadius: 5)) }
            Toggle("Move selected items to the top", isOn: $settings.moveSelectedToTop)
            Button("Clear Clipboard History…", role: .destructive) { clearConfirmation = true }
        }.formStyle(.grouped).padding(20).frame(width: 430).confirmationDialog("Clear clipboard history?", isPresented: $clearConfirmation, titleVisibility: .visible) { Button("Cancel", role: .cancel) {}; Button("Clear History", role: .destructive) { try? repository.clearRecentHistoryKeepingFavorites() } } message: { Text("This removes all recent entries. Favorites will be kept.") }.alert("Unable to update login item", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK") {} } message: { Text(errorMessage ?? "") }
    }
}
