import CoreGraphics

/// Keeps the "faded" look of cut items in sync with the cut state and
/// with what is currently visible in Finder.
@MainActor
public final class CutHighlightPresenter {
    private let frontmost: FrontmostApplicationProviding
    private let locator: CutItemLocating
    private let highlighter: CutHighlighting
    private var isShowing = false

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

    public func refresh(for state: CutState) {
        // Overlays are only safe while Finder is in front: otherwise another
        // app's window could be covering the items.
        guard case .ready(let session) = state, frontmost.isFinderFrontmost() else {
            hide()
            return
        }

        let frames = locator.frames(of: session.items)
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
