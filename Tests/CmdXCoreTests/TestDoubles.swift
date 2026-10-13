import CmdXCore
import Foundation

@MainActor
final class StubFrontmostProvider: FrontmostApplicationProviding {
    var finderIsFrontmost = true
    func isFinderFrontmost() -> Bool { finderIsFrontmost }
}

@MainActor
final class StubFocusInspector: TextFocusInspecting {
    var textFocused = false
    private(set) var queryCount = 0

    func isTextInputFocused() -> Bool {
        queryCount += 1
        return textFocused
    }
}

@MainActor
final class FakePasteboard: PasteboardReading {
    var changeCount = 0
    var urls: [URL] = []

    func fileURLs() -> [URL] { urls }

    /// Simulates another app (or the user) replacing the clipboard.
    func replaceContents(with newURLs: [URL]) {
        changeCount += 1
        urls = newURLs
    }
}

/// Records commands and, by default, behaves like Finder by putting the
/// "selected" items on the pasteboard when asked to copy.
@MainActor
final class FakeFinder: FinderCommandSending {
    private let pasteboard: FakePasteboard
    var selection: [URL] = []
    private(set) var sent: [FinderCommand] = []

    init(pasteboard: FakePasteboard) {
        self.pasteboard = pasteboard
    }

    func send(_ command: FinderCommand) {
        sent.append(command)
        // Finder leaves the pasteboard untouched when nothing is selected.
        if command == .copy, !selection.isEmpty {
            pasteboard.replaceContents(with: selection)
        }
    }
}

@MainActor
final class SpyCutEventObserver: CutEventObserving {
    private(set) var recorded: [CutEvent] = []
    func record(_ event: CutEvent) { recorded.append(event) }
}

/// Runs scheduled work only when the test says so.
@MainActor
final class ManualScheduler: Scheduling {
    private var pending: [@MainActor () -> Void] = []

    func schedule(after delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        pending.append(work)
    }

    func runUntilIdle() {
        while !pending.isEmpty {
            pending.removeFirst()()
        }
    }
}

enum Keys {
    static let cut = KeyStroke(keyCode: KeyCode.x, modifiers: .command)
    static let paste = KeyStroke(keyCode: KeyCode.v, modifiers: .command)
    static let escape = KeyStroke(keyCode: KeyCode.escape, modifiers: [])
    static let letterA = KeyStroke(keyCode: 0x00, modifiers: [])
}

enum Fixtures {
    static let file = URL(fileURLWithPath: "/Users/test/Documents/report.pdf")
    static let folder = URL(fileURLWithPath: "/Users/test/Documents/Photos", isDirectory: true)
    static let other = URL(fileURLWithPath: "/Users/test/Desktop/notes.txt")
}
