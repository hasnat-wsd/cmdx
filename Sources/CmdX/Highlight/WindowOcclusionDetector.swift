import CoreGraphics
import Foundation

/// Reports where other windows sit on screen, so desktop icons hidden
/// behind them are not highlighted on top of those windows.
///
/// Uses only window bounds, which need no Screen Recording permission.
enum WindowOcclusionDetector {
    /// Bounds (global, top-left origin) of visible windows owned by other
    /// processes, excluding the desktop itself.
    static func coveringWindowFrames() -> [CGRect] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return windows.compactMap { info in
            guard
                (info[kCGWindowOwnerPID as String] as? Int32) != ownPID,
                ((info[kCGWindowAlpha as String] as? Double) ?? 1) > 0,
                let bounds = info[kCGWindowBounds as String] as? NSDictionary
            else {
                return nil
            }
            return CGRect(dictionaryRepresentation: bounds as CFDictionary)
        }
    }
}
