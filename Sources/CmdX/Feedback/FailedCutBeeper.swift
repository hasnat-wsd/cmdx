import AppKit
import CmdXCore

/// Plays the system alert sound when a cut could not be captured, a paste
/// was swallowed or a cut could not be restored, just as Finder beeps when
/// a command is unavailable, so failures are never silent.
@MainActor
final class FailedCutBeeper: CutEventObserving {
    func record(_ event: CutEvent) {
        switch event {
        case .cutFailedClipboardUnchanged, .cutFailedNoFiles, .pasteSwallowed, .restoreUnavailable:
            NSSound.beep()
        default:
            break
        }
    }
}
