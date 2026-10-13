import AppKit
import CmdXCore

/// Uses `NSWorkspace` to check whether Finder is the active application.
@MainActor
final class WorkspaceFrontmostProvider: FrontmostApplicationProviding {
    func isFinderFrontmost() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == FinderApplication.bundleIdentifier
    }
}
