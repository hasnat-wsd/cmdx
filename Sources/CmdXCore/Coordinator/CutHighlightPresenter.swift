import CoreGraphics

/// Keeps the "faded" look of cut items in sync with the cut state and
/// with what is currently visible in Finder.
@MainActor
public final class CutHighlightPresenter {
    private let frontmost: FrontmostApplicationProviding
    private let locator: CutItemLocating
    private let highlighter: CutHighlighting
    private var isShowing = false
    /// State of the most recent `refresh`, so a search that finishes after
    /// the state moved on is discarded.
    private var latestState: CutState = .idle
    private var locating: Task<Void, Never>?

    public init(
        frontmost: FrontmostApplicationProviding,
        locator: CutItemLocating,
        highlighter: CutHighlighting
    ) {
        self.frontmost = frontmost
        self.locator = locator
        self.highlighter = highlighter
    }

    /// Whether `refresh` needs to keep being called (items can move as the
    /// user scrolls, resizes or switches folders).
    public func needsTracking(_ state: CutState) -> Bool {
        if case .ready = state { return true }
        return false
    }

    /// Hides the fade immediately when it no longer applies; otherwise
    /// starts locating the items in the background. A refresh requested
    /// while a search is running is skipped: the next one catches up.
    public func refresh(for state: CutState) {
        latestState = state
        // Overlays are only safe while Finder is in front: otherwise another
        // app's window could be covering the items.
        guard case .ready(let session) = state, frontmost.isFinderFrontmost() else {
            hide()
            return
        }
        guard locating == nil else { return }

        locating = Task { [weak self, locator] in
            let frames = await locator.frames(of: session.items)
            self?.apply(frames, for: state)
        }
    }

    /// Waits for the background search started by `refresh`, if any.
    func waitForPendingRefresh() async {
        await locating?.value
    }

    private func apply(_ frames: [CGRect], for state: CutState) {
        locating = nil
        guard state == latestState, frontmost.isFinderFrontmost() else { return }
        guard !frames.isEmpty else {
            hide()
            return
        }
        highlighter.show(frames)
        isShowing = true
    }

    private func hide() {
        guard isShowing else { return }
        highlighter.hide()
        isShowing = false
    }
}
