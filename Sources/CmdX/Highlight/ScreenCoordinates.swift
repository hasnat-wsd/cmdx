import AppKit

/// Converts between the two global coordinate systems macOS uses.
@MainActor
enum ScreenCoordinates {
    /// Accessibility / Quartz use a top-left origin on the primary display;
    /// AppKit uses a bottom-left origin on that same display.
    static func appKitRect(fromGlobal rect: CGRect) -> CGRect? {
        guard let primary = NSScreen.screens.first else { return nil }
        return CGRect(
            x: rect.minX,
            y: primary.frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
