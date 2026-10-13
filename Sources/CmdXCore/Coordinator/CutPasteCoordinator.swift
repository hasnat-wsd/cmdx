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
    private let focus: TextFocusInspecting
    private let pasteboard: PasteboardReading
    private let commands: FinderCommandSending
    private let awaiter: ClipboardChangeAwaiter
    private let observer: CutEventObserving?

    public init(
        frontmost: FrontmostApplicationProviding,
        focus: TextFocusInspecting,
        pasteboard: PasteboardReading,
        commands: FinderCommandSending,
        awaiter: ClipboardChangeAwaiter,
        observer: CutEventObserving? = nil
    ) {
        self.frontmost = frontmost
        self.focus = focus
        self.pasteboard = pasteboard
        self.commands = commands
        self.awaiter = awaiter
        self.observer = observer
    }

    /// Decides what to do with a key press. Non-shortcut keys return
    /// immediately without any further inspection.
    public func handle(_ stroke: KeyStroke) -> EventDecision {
        guard let shortcut = Shortcut(stroke) else { return .passThrough }
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
            cancel()
            return .passThrough
        }
    }

    /// Abandons any pending cut. The original items stay where they are.
    public func cancel() {
        guard state != .idle else { return }
        state = .idle
        observer?.record(.cancelled)
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
        state = .capturing
        commands.send(.copy)
        observer?.record(.copyRequested)
        awaiter.awaitChange(from: baseline) { [weak self] changed in
            self?.completeCapture(clipboardChanged: changed)
        }
        return .consume
    }

    private func completeCapture(clipboardChanged: Bool) {
        // The user may have cancelled while we were waiting.
        guard state == .capturing else { return }

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
            state = .completed(changeCount: session.changeCount)
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
