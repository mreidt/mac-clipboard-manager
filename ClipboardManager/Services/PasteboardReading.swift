import AppKit

protocol PasteboardReading: AnyObject {
    var changeCount: Int { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
}

extension NSPasteboard: PasteboardReading {}
