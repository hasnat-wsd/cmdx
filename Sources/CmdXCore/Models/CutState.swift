/// Lifecycle of a cut-and-paste operation.
public enum CutState: Equatable, Sendable {
    /// Nothing is cut.
    case idle
    /// ⌘X was pressed; waiting for Finder to place the selection on the pasteboard.
    case capturing
    /// Items are cut and will be moved on the next ⌘V.
    case ready(CutSession)
    /// The items were pasted. Like Windows, pasting the same cut again is a no-op.
    case completed(changeCount: Int)

    /// Pasteboard generation this state depends on, if any.
    var clipboardChangeCount: Int? {
        switch self {
        case .ready(let session):
            return session.changeCount
        case .completed(let changeCount):
            return changeCount
        case .idle, .capturing:
            return nil
        }
    }
}
