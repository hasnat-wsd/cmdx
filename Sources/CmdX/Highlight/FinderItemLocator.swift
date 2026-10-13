import ApplicationServices
import CmdXCore
import Foundation

/// Locates cut items in Finder's front window and on the Desktop using the
/// Accessibility API. Read-only: it never alters Finder's UI or any file.
@MainActor
final class FinderItemLocator: CutItemLocating {
    private let desktopFolder = FileManager.default
        .urls(for: .desktopDirectory, in: .userDomainMask)
        .first

    func frames(of items: [URL]) -> [CGRect] {
        guard !items.isEmpty, let pid = FinderApplication.processIdentifier else { return [] }
        let finder = AXElement.application(pid: pid)
        return frontWindowFrames(in: finder, items: items) + desktopFrames(in: finder, items: items)
    }

    // MARK: - Private

    /// Only the focused window is searched: while Finder is active it is
    /// the topmost window, so an overlay on it can never cover another app.
    private func frontWindowFrames(in finder: AXElement, items: [URL]) -> [CGRect] {
        guard let window = finder.element(kAXFocusedWindowAttribute) else { return [] }
        let matcher = FinderItemMatcher(items: items, folder: window.url(kAXDocumentAttribute))
        return AXTreeSearcher(matcher: matcher).frames(in: window)
    }

    /// Desktop icons live in a scroll area that is a direct child of the
    /// Finder application element. Icons covered by any window are skipped.
    private func desktopFrames(in finder: AXElement, items: [URL]) -> [CGRect] {
        let desktops = finder.elements(kAXChildrenAttribute).filter { $0.role == kAXScrollAreaRole }
        guard !desktops.isEmpty else { return [] }

        let searcher = AXTreeSearcher(matcher: FinderItemMatcher(items: items, folder: desktopFolder))
        let covering = WindowOcclusionDetector.coveringWindowFrames()
        return desktops
            .flatMap { searcher.frames(in: $0) }
            .filter { frame in !covering.contains { $0.intersects(frame) } }
    }
}
