import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalShortcutManager: NSObject {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    let onToggle: () -> Void
    init(onToggle: @escaping () -> Void) { self.onToggle = onToggle }
    func start() {
        guard hotKey == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in manager.onToggle() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let id = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | shiftKey), id, GetApplicationEventTarget(), 0, &hotKey)
        if status != noErr {
            let alert = NSAlert(); alert.messageText = "The shortcut ⌃⇧Space is already being used by another application."; alert.runModal()
        }
    }
    deinit { if let hotKey { UnregisterEventHotKey(hotKey) }; if let handler { RemoveEventHandler(handler) } }
}
