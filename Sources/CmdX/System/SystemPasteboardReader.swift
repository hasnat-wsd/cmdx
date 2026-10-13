import AppKit
import CmdXCore

/// Reads file URLs from the general pasteboard. Never writes to it.
@MainActor
final class SystemPasteboardReader: PasteboardReading {
    private let pasteboard: NSPasteboard

    init() {
        self.pasteboard = .general
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func fileURLs() -> [URL] {
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
        return (objects as? [URL])?.filter(\.isFileURL) ?? []
    }
}
