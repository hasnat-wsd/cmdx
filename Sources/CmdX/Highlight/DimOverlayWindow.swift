import AppKit

/// A transparent, click-through window covering one screen. It only draws
/// the fade rects and never takes focus, mouse or keyboard input.
@MainActor
final class DimOverlayWindow: NSWindow {
    private let dimView = DimOverlayView()

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        // Just above normal windows: overlays are only shown on Finder's front
        // window, and menus, sheets and Quick Look stay above them.
        level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        setAccessibilityElement(false)
        contentView = dimView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// - Parameter rects: Rects in AppKit global coordinates.
    func show(_ rects: [CGRect]) {
        dimView.rects = rects.map { $0.offsetBy(dx: -frame.minX, dy: -frame.minY) }
        orderFrontRegardless()
    }
}
