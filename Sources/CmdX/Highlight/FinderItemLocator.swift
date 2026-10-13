import ApplicationServices
import CmdXCore
import Foundation

/// Locates cut items in Finder's front window and on the Desktop using the
/// Accessibility API. Read-only: it never alters Finder's UI or any file.
///
/// The tree walk runs off the main thread: the keyboard event tap shares
/// the main thread, and must never wait behind a slow Finder.
@MainActor
final class FinderItemLocator: CutItemLocating {
    private let desktopFolder = FileManager.default
        .urls(for: .desktopDirectory, in: .userDomainMask)
        .first
    /// Finder display names for the current cut, looked up once per cut.
    private var cachedDisplayNames: (items: [URL], names: [URL: String]) = ([], [:])

    func frames(of items: [URL]) async -> [CGRect] {
        guard !items.isEmpty, let pid = FinderApplication.processIdentifier else { return [] }
        let search = FinderItemSearch(
            pid: pid,
            items: items,
            displayNames: displayNames(of: items),
            desktopFolder: desktopFolder
        )
        return await Task.detached(priority: .userInitiated) { search.frames() }.value
    }

    private func displayNames(of items: [URL]) -> [URL: String] {
        if cachedDisplayNames.items != items {
            let pairs = items.map { ($0, FileManager.default.displayName(atPath: $0.path)) }
            cachedDisplayNames = (items, Dictionary(pairs, uniquingKeysWith: { first, _ in first }))
        }
        return cachedDisplayNames.names
    }
}

/// One search of Finder's windows for the cut items. Safe to run on any thread.
private struct FinderItemSearch: Sendable {
    let pid: pid_t
    let items: [URL]
    let displayNames: [URL: String]
    let desktopFolder: URL?

    func frames() -> [CGRect] {
        let finder = AXElement.application(pid: pid)
        return frontWindowFrames(in: finder) + desktopFrames(in: finder)
    }

    /// Only the focused window is searched: while Finder is active it is
    /// the topmost window, so an overlay on it can never cover another app.
    private func frontWindowFrames(in finder: AXElement) -> [CGRect] {
        guard let window = finder.element(kAXFocusedWindowAttribute) else { return [] }
        return AXTreeSearcher(matcher: matcher(folder: window.url(kAXDocumentAttribute))).frames(in: window)
    }

    /// Desktop icons live in a scroll area that is a direct child of the
    /// Finder application element. Icons covered by any window are skipped.
    private func desktopFrames(in finder: AXElement) -> [CGRect] {
        let desktops = finder.elements(kAXChildrenAttribute).filter { $0.role == kAXScrollAreaRole }
        guard !desktops.isEmpty else { return [] }

        let searcher = AXTreeSearcher(matcher: matcher(folder: desktopFolder))
        let covering = WindowOcclusionDetector.coveringWindowFrames()
        return desktops
            .flatMap { searcher.frames(in: $0) }
            .filter { frame in !covering.contains { $0.intersects(frame) } }
    }

    private func matcher(folder: URL?) -> CutItemMatcher {
        CutItemMatcher(items: items, folder: folder, displayNames: displayNames)
    }
}
