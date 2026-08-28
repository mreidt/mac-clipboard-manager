import AppKit
import SwiftUI

@MainActor
final class ClipboardPickerPanel: NSPanel {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onEscape?(); return }
        super.keyDown(with: event)
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
            p.delegate = self; panel = p
        }
        centerOnPreferredScreen(); panel?.makeKeyAndOrderFront(nil)
    }
    func hide() { model.isPresented = false; panel?.orderOut(nil) }
    func toggle() { model.isPresented ? hide() : show() }
    private func centerOnPreferredScreen() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.main ?? NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.screens.first
        guard let screen, let panel else { return }
        let visibleFrame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: visibleFrame.midX - panel.frame.width / 2, y: visibleFrame.midY - panel.frame.height / 2))
    }
}

extension ClipboardPanelController: NSWindowDelegate { func windowDidResignKey(_ notification: Notification) { if model.isPresented { hide() } } }
