import CoreGraphics
import Foundation

/// Finds where cut items are currently visible on screen.
@MainActor
public protocol CutItemLocating: AnyObject {
    /// Frames in global screen coordinates (top-left origin, as used by
    /// the Accessibility and Quartz window APIs). Hidden items are omitted.
    /// Implementations must do slow work off the main actor.
    func frames(of items: [URL]) async -> [CGRect]
}
