import AppKit
import CmdXCore

/// Shows cut items as faded by drawing overlays on one window per screen.
@MainActor
final class DimOverlayHighlighter: CutHighlighting {
    private static let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")

    private var windows: [CGDirectDisplayID: DimOverlayWindow] = [:]

    func show(_ frames: [CGRect]) {
        let rects = frames.compactMap(ScreenCoordinates.appKitRect(fromGlobal:))
        let screens = NSScreen.screens
        discardWindows(notMatching: screens)

        for screen in screens {
            guard let displayID = Self.displayID(of: screen) else { continue }
            let onScreen = rects.filter { $0.intersects(screen.frame) }
            if onScreen.isEmpty {
                windows[displayID]?.orderOut(nil)
            } else {
                window(for: screen, displayID: displayID).show(onScreen)
            }
        }
    }

    func hide() {
        windows.values.forEach { $0.orderOut(nil) }
    }

    // MARK: - Private

    private func window(for screen: NSScreen, displayID: CGDirectDisplayID) -> DimOverlayWindow {
        if let existing = windows[displayID] {
            // Resolution or arrangement may have changed.
            if existing.frame != screen.frame {
                existing.setFrame(screen.frame, display: false)
            }
            return existing
        }
        let window = DimOverlayWindow(screen: screen)
        windows[displayID] = window
        return window
    }

    private func discardWindows(notMatching screens: [NSScreen]) {
        let connected = Set(screens.compactMap(Self.displayID(of:)))
        for (displayID, window) in windows where !connected.contains(displayID) {
            window.close()
            windows[displayID] = nil
        }
    }

    private static func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[screenNumberKey] as? NSNumber)?.uint32Value
    }
}
