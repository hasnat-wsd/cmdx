import Foundation

/// Implements Windows / Linux style cut & paste for Finder.
///
/// The coordinator never touches the file system itself. It translates
/// ⌘X into Finder's native Copy and the following ⌘V into Finder's native
/// "Move Item Here", so conflicts, undo, permissions and cross-volume
/// moves are all handled by Finder exactly as the user expects.
@MainActor
public final class CutPasteCoordinator {
    public var onStateChange: ((CutState) -> Void)?

    public private(set) var state: CutState = .idle {
        didSet {
            if state != oldValue { onStateChange?(state) }
        }
    }

    private let frontmost: FrontmostApplicationProviding
    private let focus: FocusInspecting
    private let pasteboard: PasteboardReading
    private let files: FileExistenceChecking
    private let commands: FinderCommandSending
    private let awaiter: ClipboardChangeAwaiter
    private let observer: CutEventObserving?
    /// Identifies the latest ⌘X, so a superseded capture's late result is ignored.
    private var captureID = 0

    public init(
        frontmost: FrontmostApplicationProviding,
        focus: FocusInspecting,
        pasteboard: PasteboardReading,
        files: FileExistenceChecking,
        commands: FinderCommandSending,
        awaiter: ClipboardChangeAwaiter,
        observer: CutEventObserving? = nil
    ) {
        self.frontmost = frontmost
        self.focus = focus
        self.pasteboard = pasteboard
        self.files = files
        self.commands = commands
        self.awaiter = awaiter
        self.observer = observer
    }

    /// Decides what to do with a key press. Non-shortcut keys return
    /// immediately without any further inspection.
    public func handle(_ stroke: KeyStroke) -> EventDecision {
        guard let shortcut = Shortcut(stroke) else { return .passThrough }
        // Nothing to cancel: let Esc through without querying Finder.
        if shortcut == .cancel, state == .idle { return .passThrough }

        guard frontmost.isFinderFrontmost() else {
            observer?.record(.ignoredOutsideFinder(shortcut))
            return .passThrough
        }
        guard !focus.isTextInputFocused() else {
            observer?.record(.ignoredWhileEditingText(shortcut))
            return .passThrough
        }

        invalidateIfClipboardChanged()

        switch shortcut {
        case .cut:
            return handleCut(isRepeat: stroke.isRepeat)
        case .paste:
            return handlePaste()
        case .cancel:
            // Esc that closes Quick Look or a dialog must not drop the cut.
            if focus.isFileBrowserFocused() {
                cancel()
            } else {
                observer?.record(.ignoredOutsideFileBrowser(shortcut))
            }
            return .passThrough
        }
    }

    /// Abandons any pending cut. The original items stay where they are.
    public func cancel() {
        guard state != .idle else { return }
        state = .idle
        observer?.record(.cancelled)
    }

    /// Re-arms the last pasted cut when Finder never moved its items (the
    /// paste went to the same folder, a conflict dialog was cancelled, or
    /// permission was denied). Refused if any item has left its folder.
    public func restoreCut() {
        guard case .completed(let session) = state else { return }
        guard session.items.allSatisfy(files.fileExists(at:)) else {
            observer?.record(.restoreUnavailable)
            return
        }
        state = .ready(session)
        observer?.record(.cutRestored(itemCount: session.items.count))
    }

    /// Drops the cut if the user has since copied something else,
    /// matching how a new copy replaces a cut on Windows.
    public func invalidateIfClipboardChanged() {
        guard let owned = state.clipboardChangeCount, owned != pasteboard.changeCount else { return }
        state = .idle
    }

    // MARK: - Private

    private func handleCut(isRepeat: Bool) -> EventDecision {
        guard !isRepeat, state != .capturing else { return .consume }

        let baseline = pasteboard.changeCount
        captureID += 1
        let id = captureID
        state = .capturing
        commands.send(.copy)
        observer?.record(.copyRequested)
        awaiter.awaitChange(from: baseline) { [weak self] changed in
            self?.completeCapture(id, clipboardChanged: changed)
        }
        return .consume
    }

    private func completeCapture(_ id: Int, clipboardChanged: Bool) {
        // The user may have cancelled, or cancelled and cut again, while we waited.
        guard id == captureID, state == .capturing else { return }

        guard clipboardChanged else {
            state = .idle
            observer?.record(.cutFailedClipboardUnchanged)
            return
        }
        let items = pasteboard.fileURLs()
        guard !items.isEmpty else {
            state = .idle
            observer?.record(.cutFailedNoFiles)
            return
        }
        state = .ready(CutSession(items: items, changeCount: pasteboard.changeCount))
        observer?.record(.cutCaptured(itemCount: items.count))
    }

    private func handlePaste() -> EventDecision {
        switch state {
        case .ready(let session):
            commands.send(.moveHere)
            state = .completed(session)
            observer?.record(.moveRequested(itemCount: session.items.count))
            return .consume
        case .capturing, .completed:
            // Never fall back to a plain paste here: that would silently
            // duplicate files the user intended to move.
            observer?.record(.pasteSwallowed)
            return .consume
        case .idle:
            return .passThrough
        }
    }
}
