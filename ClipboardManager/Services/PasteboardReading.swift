import AppKit

@MainActor
protocol PasteboardReading: AnyObject {
    var changeCount: Int { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
}

@MainActor
protocol PasteboardWriting: AnyObject {
    @discardableResult
    func clearContents() -> Int
    @discardableResult
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
}

extension NSPasteboard: PasteboardReading, PasteboardWriting {}
