import AppKit
import SwiftUI

@MainActor
final class ClipboardPickerPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onKeyCommand: ((ClipboardPickerKeyCommand) -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown, let command = keyCommand(for: event) else {
            super.sendEvent(event)
            return
        }

        if case .close = command {
            onEscape?()
        } else {
            onKeyCommand?(command)
        }
    }

    private func keyCommand(for event: NSEvent) -> ClipboardPickerKeyCommand? {
        // Arrow keys may carry `.numericPad` (and `.function`) even when the
        // user has pressed no meaningful modifier. Ignore those hardware flags
        // so navigation works for both the main and numeric keyboards.
        let modifiers = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function])
        let commandOnly = modifiers == .command
        let noModifiers = modifiers.isEmpty

        if noModifiers {
            switch event.keyCode {
            case 125: return .moveSelection(by: 1)
            case 126: return .moveSelection(by: -1)
            case 123: return .moveTab(by: -1)
            case 124: return .moveTab(by: 1)
            case 36, 76: return .copySelected
            case 53: return .close
            default: return nil
            }
        }

        guard commandOnly else { return nil }
        if event.keyCode == 3 { return .focusSearch }
        guard let character = event.charactersIgnoringModifiers?.first,
              let digit = character.wholeNumberValue,
              let index = (0...9).contains(digit) ? digit : nil else { return nil }
        return .copyVisible(index: index)
    }
}

@MainActor
final class ClipboardPanelController: NSObject {
    let model: ClipboardPickerViewModel
    let settings: AppSettings
    let monitor: ClipboardMonitor
    private(set) var panel: ClipboardPickerPanel?
    var onSettings: (() -> Void)?
    var onSelection: ((ClipboardEntry) -> Void)?

    init(model: ClipboardPickerViewModel, settings: AppSettings, monitor: ClipboardMonitor) { self.model = model; self.settings = settings; self.monitor = monitor }
    func show() {
        model.prepareForOpening(); model.isPresented = true; model.focusSearchToken += 1
        if panel == nil {
            let p = ClipboardPickerPanel(contentRect: NSRect(x: 0, y: 0, width: 490, height: 500), styleMask: [.borderless], backing: .buffered, defer: false)
            p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true; p.level = .floating; p.hidesOnDeactivate = true; p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
            p.contentView = NSHostingView(rootView: ClipboardPickerView(model: model, onSelect: { [weak self] e in self?.onSelection?(e) }, onSettings: { [weak self] in self?.onSettings?() }))
            p.onEscape = { [weak self] in self?.hide() }
            p.onKeyCommand = { [weak self] command in self?.handle(command) }
            p.delegate = self; panel = p
        }
        NSApp.activate(ignoringOtherApps: true)
        centerOnPreferredScreen(); panel?.makeKeyAndOrderFront(nil)
    }
    func hide() { model.isPresented = false; panel?.orderOut(nil) }
    func toggle() { model.isPresented ? hide() : show() }

    private func handle(_ command: ClipboardPickerKeyCommand) {
        switch command {
        case .close:
            hide()
        case .focusSearch:
            model.focusSearchToken += 1
        case .moveSelection, .moveTab, .copySelected, .copyVisible:
            if let entry = model.handle(command) {
                onSelection?(entry)
                hide()
            }
        }
    }
    private func centerOnPreferredScreen() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.main ?? NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.screens.first
        guard let screen, let panel else { return }
        let visibleFrame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: visibleFrame.midX - panel.frame.width / 2, y: visibleFrame.midY - panel.frame.height / 2))
    }
}

extension ClipboardPanelController: NSWindowDelegate { func windowDidResignKey(_ notification: Notification) { if model.isPresented { hide() } } }
