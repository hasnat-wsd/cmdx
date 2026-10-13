import Foundation

/// Read-only view of the system pasteboard.
@MainActor
public protocol PasteboardReading: AnyObject {
    /// Increments every time the pasteboard contents change.
    var changeCount: Int { get }
    /// File and folder URLs currently on the pasteboard.
    func fileURLs() -> [URL]
}
