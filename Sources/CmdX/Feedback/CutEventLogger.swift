import CmdXCore

/// Writes coordinator decisions to the unified log. Only reasons and item
/// counts are logged — never file names, paths or other keystrokes.
@MainActor
final class CutEventLogger: CutEventObserving {
    func record(_ event: CutEvent) {
        let log = Diagnostics.cut
        switch event {
        case .ignoredOutsideFinder(let shortcut):
            // Debug level: not persisted, only visible while streaming.
            log.debug("Ignored \(String(describing: shortcut), privacy: .public): Finder is not frontmost")
        case .ignoredWhileEditingText(let shortcut):
            log.notice("Ignored \(String(describing: shortcut), privacy: .public): text field is being edited")
        case .ignoredOutsideFileBrowser(let shortcut):
            log.notice("Ignored \(String(describing: shortcut), privacy: .public): focus is not in a browser window")
        case .copyRequested:
            log.notice("Cut: asked Finder to copy the selection")
        case .cutCaptured(let count):
            log.notice("Cut: \(count, privacy: .public) item(s) ready to move")
        case .cutFailedClipboardUnchanged:
            log.notice("Cut failed: Finder did not update the clipboard (nothing selected?)")
        case .cutFailedNoFiles:
            log.notice("Cut failed: clipboard changed but contains no files")
        case .moveRequested(let count):
            log.notice("Paste: asked Finder to move \(count, privacy: .public) item(s)")
        case .pasteSwallowed:
            log.notice("Paste ignored: cut already used or still being captured")
        case .cancelled:
            log.notice("Cut cancelled")
        case .cutRestored(let count):
            log.notice("Cut restored: \(count, privacy: .public) item(s) ready to move again")
        case .restoreUnavailable:
            log.notice("Restore refused: some cut items are no longer in their folder")
        }
    }
}
