import AppKit
import CoreGraphics

protocol PasteTarget: AnyObject {
    var processIdentifier: pid_t { get }
    var isTerminated: Bool { get }
}

extension NSRunningApplication: PasteTarget {}

@MainActor
protocol PasteTargetSystem: AnyObject {
    func frontmostApplication() -> PasteTarget?
    func activate(_ target: PasteTarget) -> Bool
    func isFrontmost(_ target: PasteTarget) -> Bool
}

final class SystemPasteTargetSystem: PasteTargetSystem {
    func frontmostApplication() -> PasteTarget? {
        NSWorkspace.shared.frontmostApplication
    }

    func activate(_ target: PasteTarget) -> Bool {
        guard let application = target as? NSRunningApplication else { return false }
        return application.activate(options: [])
    }

    func isFrontmost(_ target: PasteTarget) -> Bool {
        frontmostApplication()?.processIdentifier == target.processIdentifier
    }
}

@MainActor
protocol PasteFocusRestoring: AnyObject {
    func waitUntilFrontmost(_ target: PasteTarget) async -> Bool
}

final class SystemPasteFocusRestorer: PasteFocusRestoring {
    private let system: PasteTargetSystem

    init(system: PasteTargetSystem) { self.system = system }

    func waitUntilFrontmost(_ target: PasteTarget) async -> Bool {
        let start = ContinuousClock.now
        try? await Task.sleep(for: .milliseconds(100))
        while !system.isFrontmost(target) {
            guard ContinuousClock.now - start < .milliseconds(300) else { return false }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return true
    }
}

@MainActor
protocol PasteKeyEventSending: AnyObject {
    func sendCommandV() -> Bool
}

final class SystemPasteKeyEventSender: PasteKeyEventSending {
    func sendCommandV() -> Bool {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            return false
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}

@MainActor
final class AutomaticPasteCoordinator {
    private let repository: ClipboardRepositoryProtocol
    private let settings: AppSettings
    private let monitor: ClipboardMonitor
    private let pasteboard: PasteboardWriting
    private let permission: AccessibilityPermissionChecking
    private let targetSystem: PasteTargetSystem
    private let focusRestorer: PasteFocusRestoring
    private let keySender: PasteKeyEventSending
    private let closePicker: () -> Void
    private let playSound: () -> Void
    private let onCopyOnlyFallback: () -> Void
    private(set) var isOperationInProgress = false

    init(
        repository: ClipboardRepositoryProtocol,
        settings: AppSettings,
        monitor: ClipboardMonitor,
        pasteboard: PasteboardWriting = NSPasteboard.general,
        permission: AccessibilityPermissionChecking? = nil,
        targetSystem: PasteTargetSystem? = nil,
        focusRestorer: PasteFocusRestoring? = nil,
        keySender: PasteKeyEventSending? = nil,
        closePicker: @escaping () -> Void = {},
        playSound: @escaping () -> Void = {},
        onCopyOnlyFallback: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.settings = settings
        self.monitor = monitor
        self.pasteboard = pasteboard
        let resolvedTargetSystem = targetSystem ?? SystemPasteTargetSystem()
        self.permission = permission ?? AccessibilityPermissionManager()
        self.targetSystem = resolvedTargetSystem
        self.focusRestorer = focusRestorer ?? SystemPasteFocusRestorer(system: resolvedTargetSystem)
        self.keySender = keySender ?? SystemPasteKeyEventSender()
        self.closePicker = closePicker
        self.playSound = playSound
        self.onCopyOnlyFallback = onCopyOnlyFallback
    }

    func selectAndPaste(_ entry: ClipboardEntry, target: PasteTarget?) async {
        guard !isOperationInProgress else { return }
        isOperationInProgress = true
        defer { isOperationInProgress = false }

        pasteboard.clearContents()
        pasteboard.setString(entry.text, forType: .string)
        monitor.acknowledgeCurrentChange()
        try? repository.markSelected(entryID: entry.id, moveToTop: settings.moveSelectedToTop)
        closePicker()
        playSound()

        guard permission.isTrusted() else {
            permission.requestPermissionPromptIfNeeded()
            onCopyOnlyFallback()
            return
        }
        guard let target, !target.isTerminated,
              target.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              targetSystem.activate(target) else { return }
        guard await focusRestorer.waitUntilFrontmost(target), targetSystem.isFrontmost(target) else { return }
        _ = keySender.sendCommandV()
    }
}
