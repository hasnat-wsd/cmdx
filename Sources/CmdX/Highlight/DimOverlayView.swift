import AppKit

/// Paints the "faded" look: the content background colour at partial
/// opacity, which makes whatever is underneath appear semi-transparent.
final class DimOverlayView: NSView {
    private static let opacity: CGFloat = 0.6
    private static let cornerRadius: CGFloat = 4

    /// Rects to fade, in this view's coordinate space.
    var rects: [CGRect] = [] {
        didSet {
            if rects != oldValue { needsDisplay = true }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Resolves to white or dark grey with the current appearance,
        // matching Finder's content background in light and dark mode.
        NSColor.textBackgroundColor.withAlphaComponent(Self.opacity).setFill()
        for rect in rects where rect.intersects(dirtyRect) {
            NSBezierPath(roundedRect: rect, xRadius: Self.cornerRadius, yRadius: Self.cornerRadius).fill()
        }
    }
}
