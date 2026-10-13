import CoreGraphics

/// Visually marks cut items (e.g. by fading them out).
@MainActor
public protocol CutHighlighting: AnyObject {
    /// Highlights exactly these frames (global, top-left origin), replacing
    /// any previous highlight.
    func show(_ frames: [CGRect])
    func hide()
}
