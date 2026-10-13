import Foundation

/// Items that have been cut and are waiting to be pasted.
public struct CutSession: Equatable, Sendable {
    /// File-system locations of the cut files and folders.
    public let items: [URL]
    /// Pasteboard generation that holds `items`. If the pasteboard changes
    /// (the user copies something else), the cut is no longer valid.
    public let changeCount: Int

    public init(items: [URL], changeCount: Int) {
        self.items = items
        self.changeCount = changeCount
    }

    public var displayNames: [String] {
        items.map(\.lastPathComponent)
    }
}
