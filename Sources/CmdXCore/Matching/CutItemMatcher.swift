import Foundation

/// Decides whether something shown in Finder is one of the cut items.
///
/// Matches by exact file URL when Finder exposes one. Otherwise it matches
/// by name, but only for items whose parent folder is the folder being
/// shown, so a same-named file elsewhere is never highlighted. Names
/// include Finder's display name, which hides extensions when the user
/// has "Show all filename extensions" turned off.
public struct CutItemMatcher: Sendable {
    private let paths: Set<String>
    private let namesInFolder: Set<String>

    /// - Parameter displayNames: Names Finder shows for some items, when
    ///   they differ from the file name.
    public init(items: [URL], folder: URL?, displayNames: [URL: String] = [:]) {
        paths = Set(items.map(Self.normalizedPath))
        guard let folder, folder.isFileURL else {
            namesInFolder = []
            return
        }
        let folderPath = Self.normalizedPath(folder)
        let itemsInFolder = items.filter { Self.normalizedPath($0.deletingLastPathComponent()) == folderPath }
        namesInFolder = Set(
            itemsInFolder.flatMap { [$0.lastPathComponent, displayNames[$0]].compactMap { $0 } }
                .filter { !$0.isEmpty }
        )
    }

    /// - Parameters:
    ///   - url: The file URL Finder reports for the element, if any.
    ///   - labels: Visible names of the element. Callers pass only labels
    ///     that can be file names (not a "Kind" or "Date" column).
    public func matches(url: URL?, labels: [String]) -> Bool {
        if let url, url.isFileURL, paths.contains(Self.normalizedPath(url)) {
            return true
        }
        return labels.contains(where: namesInFolder.contains)
    }

    private static func normalizedPath(_ url: URL) -> String {
        let path = url.standardizedFileURL.path
        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}
