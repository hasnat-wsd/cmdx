/// Notable decisions made by the coordinator, for diagnostics and feedback.
/// Carries counts only, never file names or other personal data.
public enum CutEvent: Equatable, Sendable {
    case ignoredOutsideFinder(Shortcut)
    case ignoredWhileEditingText(Shortcut)
    /// Finder is in front but focus is in Quick Look, a sheet or a dialog.
    case ignoredOutsideFileBrowser(Shortcut)
    case copyRequested
    case cutCaptured(itemCount: Int)
    /// Finder did not update the clipboard (usually: nothing was selected).
    case cutFailedClipboardUnchanged
    /// The clipboard changed but holds no files (e.g. text was copied).
    case cutFailedNoFiles
    case moveRequested(itemCount: Int)
    case pasteSwallowed
    case cancelled
    /// A pasted cut was re-armed because its items never left their folder.
    case cutRestored(itemCount: Int)
    /// The cut could not be restored: some items were moved or are gone.
    case restoreUnavailable
}
