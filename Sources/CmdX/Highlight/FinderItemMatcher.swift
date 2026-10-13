import ApplicationServices
import Foundation

/// Decides whether an Accessibility node represents one of the cut items.
///
/// Matches by exact file URL when Finder exposes one. Otherwise it matches
/// by name, but only for items whose parent folder is the folder being
/// shown, so a same-named file elsewhere is never highlighted.
struct FinderItemMatcher {
    private static let nameBearingRoles: Set<String> = [
        kAXImageRole,
        kAXTextFieldRole,
        kAXStaticTextRole,
        kAXCellRole
    ]

    private let paths: Set<String>
    private let namesInFolder: Set<String>

    init(items: [URL], folder: URL?) {
        paths = Set(items.map(Self.normalizedPath))
        guard let folder, folder.isFileURL else {
            namesInFolder = []
            return
        }
        let folderPath = Self.normalizedPath(folder)
        namesInFolder = Set(
            items
                .filter { Self.normalizedPath($0.deletingLastPathComponent()) == folderPath }
                .map(\.lastPathComponent)
        )
    }

    func matches(_ node: AXNodeSnapshot) -> Bool {
        if let url = node.url, url.isFileURL, paths.contains(Self.normalizedPath(url)) {
            return true
        }
        guard !namesInFolder.isEmpty, let role = node.role, Self.nameBearingRoles.contains(role) else {
            return false
        }
        return node.labels.contains(where: namesInFolder.contains)
    }

    private static func normalizedPath(_ url: URL) -> String {
        let path = url.standardizedFileURL.path
        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}
