import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleClipboardPicker = Self(
        "toggleClipboardPicker",
        default: .init(.space, modifiers: [.control, .shift])
    )
}

@MainActor
final class GlobalShortcutManager {
    let onToggle: () -> Void
    private var isStarted = false

    init(onToggle: @escaping () -> Void) { self.onToggle = onToggle }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        KeyboardShortcuts.onKeyUp(for: .toggleClipboardPicker) { [weak self] in
            self?.onToggle()
        }
    }
}
