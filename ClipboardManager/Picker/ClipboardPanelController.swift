import AppKit
import SwiftUI

@MainActor
final class ClipboardPickerPanel: NSPanel {
    var commandHandler: ((PanelCommand) -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), let digit = Int(event.charactersIgnoringModifiers ?? ""), (0...9).contains(digit) { commandHandler?(.digit(digit)); return true }
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "f" { commandHandler?(.focusSearch); return true }
        return super.performKeyEquivalent(with: event)
    }
    override func keyDown(with event: NSEvent) {
        switch event.keyCode { case 125: commandHandler?(.down); case 126: commandHandler?(.up); case 36: commandHandler?(.returnKey); case 53: commandHandler?(.escape); default: super.keyDown(with: event) }
    }
}
enum PanelCommand { case up, down, returnKey, escape, digit(Int), focusSearch }

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
        if panel == nil { let p = ClipboardPickerPanel(contentRect: NSRect(x: 0, y: 0, width: 490, height: 500), styleMask: [.borderless], backing: .buffered, defer: false); p.isOpaque = false; p.backgroundColor = .clear; p.level = .floating; p.hidesOnDeactivate = true; p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]; p.contentView = NSHostingView(rootView: ClipboardPickerView(model: model, onSelect: { [weak self] e in self?.onSelection?(e) }, onSettings: { [weak self] in self?.onSettings?() })); p.commandHandler = { [weak self] command in self?.handle(command) }; p.delegate = self; panel = p }
        panel?.center(); NSApp.activate(ignoringOtherApps: true); panel?.makeKeyAndOrderFront(nil)
    }
    func hide() { model.isPresented = false; panel?.orderOut(nil) }
    func toggle() { model.isPresented ? hide() : show() }
    private func handle(_ command: PanelCommand) { switch command { case .up: model.moveSelection(by: -1); case .down: model.moveSelection(by: 1); case .escape: hide(); case .focusSearch: model.focusSearchToken += 1; case .digit(let d): if let i = model.digitIndex(d), let entry = model.entry(at: i) { onSelection?(entry) }; case .returnKey: if let i = model.selectedIndex, let entry = model.entry(at: i) { onSelection?(entry) } } }
}

extension ClipboardPanelController: NSWindowDelegate { func windowDidResignKey(_ notification: Notification) { if model.isPresented { hide() } } }
