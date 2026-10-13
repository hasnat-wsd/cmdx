/// Lifecycle of a cut-and-paste operation.
public enum CutState: Equatable, Sendable {
    /// Nothing is cut.
    case idle
    /// ⌘X was pressed; waiting for Finder to place the selection on the pasteboard.
    case capturing
    /// Items are cut and will be moved on the next ⌘V.
    case ready(CutSession)
    /// Finder was asked to move the items. Like Windows, pasting the same
    /// cut again is a no-op; the session is kept so the cut can be restored
    /// if Finder never moved them.
    case completed(CutSession)

    /// Pasteboard generation this state depends on, if any.
    var clipboardChangeCount: Int? {
        switch self {
        case .ready(let session), .completed(let session):
            return session.changeCount
        case .idle, .capturing:
            return nil
        }
    }
}
